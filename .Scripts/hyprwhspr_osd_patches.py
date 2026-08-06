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


def apply_all() -> None:
    apply_osd_chrome()
    apply_osd_position()
