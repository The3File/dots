#!/usr/bin/env python3
"""Patches applied inside the hyprwhspr process and the Mic-OSD daemon.

Mic-OSD runs as a separate Python subprocess, so chrome/position patches must
be imported there too (see hyprwhspr-service daemon inject).
"""

from __future__ import annotations

import math

# Match Hyprland decoration.rounding / fuzzel / dunst
OSD_RADIUS = 10
OSD_BORDER_WIDTH = 2
# Waybar is 26px; leave clear air above it and from the left edge (gaps_out≈15)
OSD_MARGIN_BOTTOM = 50
OSD_MARGIN_LEFT = 16

# Waveform drama: level-feed buckets are raw RMS (~0.001–0.02 on this ThinkPad
# mic). Upstream amplification=4.0 leaves bars near the noise floor.
OSD_WAVEFORM_GAIN = 75.0
OSD_WAVEFORM_GAMMA = 0.78  # <1 expands quiet speech into visible motion
OSD_WAVEFORM_RISE = 0.68
OSD_WAVEFORM_DECAY = 0.80
# Post-gain/gamma (0..1): below this → silence. Raise if room noise still wiggles.
OSD_WAVEFORM_NOISE_GATE = 0.24

# "sine" = amplitude-driven scene wave; "bars" = upstream equalizer (easy revert).
OSD_WAVEFORM_RENDER = "sine"
# Sine look: cycles across the strip; ends pinned to midline via sin(π·t) window.
OSD_SINE_CYCLES = 2.0
OSD_SINE_MIN_AMP = 0.0  # quiet → flat line; speech lifts the middle
OSD_SINE_HEIGHT = 0.48  # fraction of wave strip used as max peak
OSD_SINE_PIN_ENDS = True  # multiply by sin(π·t) so left/right stay on center_y
# One shared amplitude (mean/max of buckets) + dense samples → soft pure sine.
OSD_SINE_SOFT = True
OSD_SINE_SAMPLES = 96


def _rounded_rect(cr, x: float, y: float, w: float, h: float, radius: float) -> None:
    radius = min(radius, w / 2.0, h / 2.0)
    cr.new_sub_path()
    cr.arc(x + w - radius, y + radius, radius, -math.pi / 2, 0)
    cr.arc(x + w - radius, y + h - radius, radius, 0, math.pi / 2)
    cr.arc(x + radius, y + h - radius, radius, math.pi / 2, math.pi)
    cr.arc(x + radius, y + radius, radius, math.pi, 3 * math.pi / 2)
    cr.close_path()


def apply_osd_chrome() -> None:
    """Transparent corners + rounded fill/border."""
    import cairo
    from mic_osd.theme import theme
    from mic_osd.visualizations.base import BaseVisualization

    def draw_background(self, cr, width: int, height: int) -> None:
        # Clear full surface so corners are truly transparent (not opaque black).
        cr.save()
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(0, 0, 0, 0)
        cr.rectangle(0, 0, width, height)
        cr.fill()
        cr.restore()

        radius = OSD_RADIUS
        cr.set_source_rgba(*self.background_color)
        _rounded_rect(cr, 0.5, 0.5, width - 1.0, height - 1.0, radius)
        cr.fill()

        border_color = theme.border
        if not border_color:
            return
        if len(border_color) == 3:
            cr.set_source_rgb(*border_color)
        else:
            cr.set_source_rgba(*border_color)
        cr.set_line_width(OSD_BORDER_WIDTH)
        inset = OSD_BORDER_WIDTH / 2.0
        _rounded_rect(
            cr,
            inset,
            inset,
            width - OSD_BORDER_WIDTH,
            height - OSD_BORDER_WIDTH,
            max(0.0, radius - inset),
        )
        cr.stroke()

    BaseVisualization.draw_background = draw_background


def apply_osd_position() -> None:
    """Bottom-left, above waybar, inset from left edge."""
    from mic_osd.window import OSDWindow, LAYER_SHELL_AVAILABLE

    if not LAYER_SHELL_AVAILABLE:
        return

    from gi.repository import Gtk4LayerShell

    def _setup_layer_shell(self) -> None:
        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_namespace(self, "mic-osd")
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)

        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.BOTTOM, True)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.LEFT, True)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.RIGHT, False)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.TOP, False)

        Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.BOTTOM, OSD_MARGIN_BOTTOM)
        Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.LEFT, OSD_MARGIN_LEFT)

        Gtk4LayerShell.set_exclusive_zone(self, -1)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.NONE)

    OSDWindow._setup_layer_shell = _setup_layer_shell


def apply_osd_waveform_drama() -> None:
    """Punchier Mic-OSD bars for quiet laptop mics."""
    import numpy as np
    from mic_osd.visualizations.base import BaseVisualization
    from mic_osd.visualizations.waveform import WaveformVisualization

    _orig_init = WaveformVisualization.__init__

    def _init(self, *args, **kwargs):
        _orig_init(self, *args, **kwargs)
        self.amplification = OSD_WAVEFORM_GAIN
        self.rise_rate = OSD_WAVEFORM_RISE
        self.decay_rate = OSD_WAVEFORM_DECAY

    def update(self, level: float, samples: np.ndarray = None):
        BaseVisualization.update(self, level, samples)

        if samples is not None and len(samples) > 0:
            # Level feed already sends one RMS bucket per bar (num_bars floats).
            # Fall back to chunking if a raw PCM buffer arrives instead.
            if len(samples) == self.num_bars:
                bucket_rms = np.asarray(samples, dtype=np.float64)
            else:
                chunk_size = len(samples) // self.num_bars
                if chunk_size <= 0:
                    self.bar_heights *= self.decay_rate
                    self.state_manager.update()
                    return
                bucket_rms = np.array(
                    [
                        float(
                            np.sqrt(
                                np.mean(
                                    samples[i * chunk_size : (i + 1) * chunk_size] ** 2
                                )
                            )
                        )
                        for i in range(self.num_bars)
                    ],
                    dtype=np.float64,
                )

            # Gain + gamma: quiet speech becomes large motion; loud still caps at 1.
            scaled = np.clip(bucket_rms * self.amplification, 0.0, None)
            new_heights = np.clip(np.power(scaled, OSD_WAVEFORM_GAMMA), 0.0, 1.0)

            # Noise gate: subtract threshold and renormalize so speech still hits 1.
            gate = OSD_WAVEFORM_NOISE_GATE
            if gate > 0.0:
                denom = max(1e-6, 1.0 - gate)
                new_heights = np.clip((new_heights - gate) / denom, 0.0, 1.0)

            for i in range(self.num_bars):
                if new_heights[i] > self.bar_heights[i]:
                    self.bar_heights[i] = (
                        self.rise_rate * new_heights[i]
                        + (1 - self.rise_rate) * self.bar_heights[i]
                    )
                else:
                    self.bar_heights[i] *= self.decay_rate
                    if self.bar_heights[i] < new_heights[i]:
                        self.bar_heights[i] = new_heights[i]
                if self.bar_heights[i] < 0.02:
                    self.bar_heights[i] = 0.0
        else:
            self.bar_heights *= self.decay_rate
            self.bar_heights[self.bar_heights < 0.02] = 0.0

        self.state_manager.update()

    WaveformVisualization.__init__ = _init
    WaveformVisualization.update = update


def apply_osd_waveform_render() -> None:
    """Replace equalizer bars with a sine scene-wave when RENDER=sine."""
    if OSD_WAVEFORM_RENDER != "sine":
        return

    import cairo
    from mic_osd.theme import theme
    from mic_osd.visualizations.base import VisualizerState
    from mic_osd.visualizations.waveform import WaveformVisualization

    def draw(self, cr: cairo.Context, width: int, height: int) -> None:
        padding = 16
        indicator_width = 30
        wave_start_x = padding + indicator_width
        wave_width = width - wave_start_x - padding
        wave_height = height - (padding * 2)
        center_y = height / 2.0

        self._draw_recording_indicator(cr, padding, center_y)

        n = max(2, int(self.num_bars))
        bar_left = theme.bar_left
        bar_right = theme.bar_right

        is_processing = self.state_manager.current_state == VisualizerState.PROCESSING
        is_success = self.state_manager.current_state == VisualizerState.SUCCESS
        wave_phase = self.state_manager.animation_phase
        # Gentle drift while recording; full speed while processing.
        phase = wave_phase if is_processing else wave_phase * 0.35
        pulse_value = self.state_manager.get_animation_value() if is_success else 1.0

        heights = [float(h) for h in self.bar_heights[:n]]
        if OSD_SINE_SOFT:
            # Single envelope — no per-bucket ripples on the sine.
            mean_amp = sum(heights) / n
            max_amp = max(heights) if heights else 0.0
            base_amp = 0.45 * mean_amp + 0.55 * max_amp
            samples = max(8, int(OSD_SINE_SAMPLES))
        else:
            base_amp = None
            samples = n

        points: list[tuple[float, float]] = []
        for i in range(samples):
            t = i / (samples - 1)
            if OSD_SINE_SOFT:
                amp = base_amp
            else:
                amp = heights[min(i, n - 1)]

            if is_processing:
                # Soft global breathe — avoid per-point harmonics (short ripples).
                amp = max(amp, 0.7) * (0.82 + 0.18 * math.sin(wave_phase))
            elif is_success:
                amp = amp * (0.7 + 0.3 * pulse_value)

            amp = max(OSD_SINE_MIN_AMP, min(1.0, amp))

            sine = math.sin(t * 2 * math.pi * OSD_SINE_CYCLES + phase)
            if OSD_SINE_PIN_ENDS:
                sine *= math.sin(math.pi * t)
            x = wave_start_x + t * wave_width
            y = center_y - amp * (wave_height * OSD_SINE_HEIGHT) * sine
            points.append((x, y))

        if not points:
            self._draw_elapsed_time(cr, width, height)
            return

        opacity = pulse_value if is_success else 1.0

        # Soft fill under the curve down to the midline.
        cr.new_path()
        cr.move_to(points[0][0], center_y)
        cr.line_to(points[0][0], points[0][1])
        for x, y in points[1:]:
            cr.line_to(x, y)
        cr.line_to(points[-1][0], center_y)
        cr.close_path()
        mid_r = (bar_left[0] + bar_right[0]) * 0.5
        mid_g = (bar_left[1] + bar_right[1]) * 0.5
        mid_b = (bar_left[2] + bar_right[2]) * 0.5
        cr.set_source_rgba(mid_r, mid_g, mid_b, 0.18 * opacity)
        cr.fill()

        # Glow pass
        cr.new_path()
        cr.move_to(*points[0])
        for x, y in points[1:]:
            cr.line_to(x, y)
        cr.set_line_width(5.0)
        cr.set_line_cap(cairo.LINE_CAP_ROUND)
        cr.set_line_join(cairo.LINE_JOIN_ROUND)
        cr.set_source_rgba(mid_r, mid_g, mid_b, 0.28 * opacity)
        cr.stroke()

        # Gradient stroke: short segments left → right theme colors.
        cr.set_line_width(2.0)
        cr.set_line_cap(cairo.LINE_CAP_ROUND)
        cr.set_line_join(cairo.LINE_JOIN_ROUND)
        for i in range(len(points) - 1):
            t = i / max(1, len(points) - 2)
            r = bar_left[0] * (1 - t) + bar_right[0] * t
            g = bar_left[1] * (1 - t) + bar_right[1] * t
            b = bar_left[2] * (1 - t) + bar_right[2] * t
            cr.set_source_rgba(r, g, b, 0.92 * opacity)
            cr.move_to(*points[i])
            cr.line_to(*points[i + 1])
            cr.stroke()

        self._draw_elapsed_time(cr, width, height)

    WaveformVisualization.draw = draw


def apply_osd_elapsed_fix() -> None:
    """Fix Mic-OSD MM:SS drifting across recordings.

    Upstream leaves WaveformVisualization._recording_start_time set when cancel
    (or any path) hides without writing a non-recording state. The next take
    writes ``recording`` again; the daemon poll skips ``set_state`` because
    ``_last_visualizer_state`` is still ``recording``, so the clock keeps
    counting from the previous take.

    Also freeze the clock on ``processing`` (like pause) instead of zeroing it.
    """
    import time

    from mic_osd.main import MicOSD, VISUALIZER_STATE_FILE
    from mic_osd.visualizations.waveform import WaveformVisualization

    def _reset_elapsed(viz) -> None:
        if viz is None:
            return
        if hasattr(viz, "_recording_start_time"):
            viz._recording_start_time = None
            viz._elapsed_seconds = 0.0
            viz._show_elapsed_time = False

    def set_state(self, state_str: str) -> None:
        self.state_manager.set_state_from_string(state_str)

        if state_str == "recording":
            if self._recording_start_time is None:
                self._recording_start_time = time.time()
            self._show_elapsed_time = True
        elif state_str in ("paused", "processing"):
            # Freeze: keep final duration visible, stop incrementing.
            if self._recording_start_time is not None:
                self._elapsed_seconds += time.time() - self._recording_start_time
                self._recording_start_time = None
            self._show_elapsed_time = True
        else:
            self._recording_start_time = None
            self._elapsed_seconds = 0.0
            self._show_elapsed_time = False

    WaveformVisualization.set_state = set_state

    _orig_hide = MicOSD._hide

    def _hide(self):
        _orig_hide(self)
        # Next show must re-apply state even if it is again "recording".
        self._last_visualizer_state = None
        _reset_elapsed(getattr(self, "visualization", None))

    MicOSD._hide = _hide

    _orig_show = MicOSD._show

    def _show(self):
        already_visible = bool(
            self.visible and self.audio_monitor and self.update_timer_id
        )
        # Force poll / re-apply so a new session cannot inherit the prior clock.
        self._last_visualizer_state = None
        _orig_show(self)

        if not already_visible:
            return

        # Upstream _show early-returns when still visible (e.g. success animation
        # interrupted by a new take). Re-read state and start a fresh clock.
        state = "recording"
        try:
            if VISUALIZER_STATE_FILE.exists():
                state = VISUALIZER_STATE_FILE.read_text().strip() or "recording"
        except Exception:
            pass

        self._last_visualizer_state = state
        viz = getattr(self, "visualization", None)
        if state == "recording":
            _reset_elapsed(viz)
        if viz is not None and hasattr(viz, "set_state"):
            viz.set_state(state)
        if self.window and hasattr(self.window, "set_visualizer_state"):
            self.window.set_visualizer_state(state)

    MicOSD._show = _show


def apply_all() -> None:
    apply_osd_chrome()
    apply_osd_position()
    apply_osd_waveform_drama()
    apply_osd_waveform_render()
    apply_osd_elapsed_fix()
