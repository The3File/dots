pragma Singleton

import QtQuick
import Quickshell
import qs

// Menuens indhold: hvilke sider der findes, og hvad linjerne goer.
//
// Handlingerne ligger IKKE her. De ligger i ~/.Scripts/fuzzel_nm og
// ~/.Scripts/btcon, som allerede virkede, og som pillen nu kalder i stedet for
// at have sin egen halve udgave. Det er ikke genbrug for genbrugets skyld:
// btcon husker enheder BlueZ selv smider vaek, vaekker dem med et kort scan og
// flytter lydudgangen med over -- og fuzzel_nm arbejder paa NetworkManagers
// profiler, ikke kun paa wifi. Ingen af delene findes i Quickshells egne
// API'er. Skrev vi det om, mistede vi det.
//
// Til at VISE hvad der er forbundet lige nu bruges Wifi og Bt (Quickshells
// egne, som opdaterer sig selv). Scriptene kaldes kun naar der skal ske noget.
//
// En linje: { label, hint, mark, color, run, alt }
//   hint maa vaere en funktion -- saa opdaterer den sig selv.
//   mark er kuglen forrest. alt er hoejreklik.
Singleton {
    id: root

    readonly property string nmScript: `${Config.scripts}/fuzzel_nm`
    readonly property string btScript: `${Config.scripts}/btcon`
    readonly property string perfScript: `${Config.scripts}/perf-mode`
    readonly property string clipScript: `${Config.scripts}/fuzzel_clip`
    readonly property string sysScript: `${Config.scripts}/bye`

    // ---- roden -----------------------------------------------------------
    function rootPage(): var {
        return {
            title: "",
            load: () => Menu.fill([
                {
                    label: "wifi",
                    hint: () => Wifi.connected ? Wifi.ssid
                        : (Wifi.enabled ? "ikke forbundet" : "slået fra"),
                    run: () => Menu.push(root.wifiPage())
                },
                {
                    label: "bluetooth",
                    hint: () => Bt.anyConnected ? Bt.label(Bt.connectedDevices[0])
                        : (Bt.enabled ? "ingen enhed" : "slået fra"),
                    run: () => Menu.push(root.btPage())
                },
                {
                    // Listen ligger IKKE her i kroppen. Den folder sig ud i
                    // output-pillen ved siden af, hvor beskederne kommer ind --
                    // saa der kun er ét sted at laese dem, og menuen ikke
                    // staar aaben oven i det.
                    label: "beskeder",
                    hint: () => Notifs.count === 0 ? "ingen" : `${Notifs.count}`,
                    run: () => {
                        if (Notifs.openList()) { Menu.close(); return; }
                        Menu.status = "ingen beskeder";
                    }
                },
                {
                    label: "udklip",
                    run: () => Menu.push(root.clipPage())
                },
                {
                    label: "ydelse",
                    hint: () => root.perfNavn(Perf.mode),
                    hintColor: Perf.color,
                    run: () => Menu.push(root.perfPage())
                },
                {
                    label: "sluk",
                    color: Theme.color8,
                    run: () => Menu.push(root.slukPage())
                }
            ])
        };
    }

    // ---- wifi ------------------------------------------------------------
    // Samme liste som fuzzel_nm's menu: NetworkManagers profiler, aktive
    // foerst markeret, og de to handlinger nederst.
    function wifiPage(): var {
        return {
            title: "wifi",
            load: () => nm.run(["list"], text => {
                const rows = nm.lines(text).map(line => {
                    const parts = line.split("\t");
                    const on = parts[0] === "*";
                    const name = parts.slice(1).join("\t");
                    return {
                        label: name,
                        mark: on ? "●" : "○",
                        color: on ? Theme.color4 : Theme.foreground,
                        run: () => nm.run([on ? "down" : "up", name],
                                          () => Menu.refresh())
                    };
                });
                rows.push({
                    label: "nyt wifi",
                    mark: "+",
                    color: Theme.color5,
                    run: () => Menu.push(root.wifiScanPage())
                });
                rows.push({
                    label: "slet forbindelse",
                    mark: "-",
                    color: Theme.color5,
                    run: () => Menu.push(root.wifiDeletePage())
                });
                Menu.fill(rows);
            })
        };
    }

    function wifiScanPage(): var {
        return {
            title: "nyt wifi",
            load: () => nm.run(["ssids"], text => {
                Menu.fill(nm.lines(text).map(line => {
                    const parts = line.split("\t");
                    const strength = parseInt(parts[0]) || 0;
                    const security = (parts[1] ?? "").trim();
                    const ssid = parts.slice(2).join("\t");
                    return {
                        label: ssid,
                        hint: `${strength}%`,
                        hintColor: Theme.rampColor(strength),
                        mark: security === "" ? "○" : "•",
                        run: () => {
                            // Aabent net: ingen grund til at spoerge om noget.
                            if (security === "") {
                                nm.run(["connect", ssid], () => Menu.back());
                                return;
                            }
                            Menu.ask(ssid, true, pass => {
                                if (pass === "") return;
                                nm.run(["connect", ssid, pass], () => Menu.back());
                            });
                        }
                    };
                }));
            })
        };
    }

    function wifiDeletePage(): var {
        return {
            title: "slet forbindelse",
            load: () => nm.run(["list"], text => {
                Menu.fill(nm.lines(text).map(line => {
                    const name = line.split("\t").slice(1).join("\t");
                    return {
                        label: name,
                        mark: "-",
                        run: () => nm.run(["delete", name], () => Menu.refresh())
                    };
                }));
            })
        };
    }

    // ---- bluetooth -------------------------------------------------------
    // Samme fire punkter som btcon's hovedmenu.
    function btPage(): var {
        return {
            title: "bluetooth",
            load: () => bt.run(["power"], text => {
                const on = (text ?? "").trim() === "yes";
                Menu.fill([
                    {
                        label: "gemte enheder",
                        run: () => Menu.push(root.btDevicesPage())
                    },
                    {
                        label: "scan + par ny enhed",
                        run: () => Menu.push(root.btScanPage())
                    },
                    {
                        label: "afbryd alle forbundne",
                        run: () => bt.run(["disconnect", "all"], () => Menu.refresh())
                    },
                    {
                        label: "strøm",
                        hint: on ? "til" : "fra",
                        hintColor: on ? Theme.stateGood : Theme.color8,
                        run: () => bt.run(["power", on ? "off" : "on"],
                                          () => Menu.refresh())
                    }
                ]);
            })
        };
    }

    // btcon list: "navn [on|trusted|paired|ok]  MAC"
    function _parseDevice(line: string): var {
        const mac = line.slice(-17);
        const head = line.slice(0, -17).trim();
        const bracket = head.indexOf(" [");
        const name = bracket >= 0 ? head.slice(0, bracket) : head;
        const flags = bracket >= 0
            ? head.slice(bracket + 2).replace(/\]$/, "").split("|") : [];
        return {
            mac: mac,
            name: name,
            connected: flags[0] === "on",
            trusted: flags[1] === "trusted",
            paired: flags[2] === "paired",
            saved: flags[2] === "saved",
            blocked: flags[3] === "blocked"
        };
    }

    function btDevicesPage(): var {
        return {
            title: "gemte enheder",
            load: () => bt.run(["list"], text => {
                Menu.fill(bt.lines(text).map(line => {
                    const d = root._parseDevice(line);
                    return {
                        label: d.name,
                        hint: d.connected ? "forbundet"
                            : (d.saved ? "gemt" : (d.paired ? "parret" : "kendt")),
                        mark: d.connected ? "●" : "○",
                        color: d.connected ? Theme.color4 : Theme.foreground,
                        run: () => Menu.push(root.btDevicePage(d.mac, d.name))
                    };
                }));
            })
        };
    }

    // Samme handlinger som btcon's device_action_menu, i samme raekkefoelge.
    function btDevicePage(mac: string, name: string): var {
        return {
            title: name,
            load: () => bt.run(["list"], text => {
                const line = bt.lines(text).find(l => l.indexOf(mac) >= 0);
                const d = line ? root._parseDevice(line)
                    : { connected: false, trusted: false, paired: false,
                        saved: true, blocked: false };

                const act = (args) => () => bt.run(args, () => Menu.refresh());
                const rows = [];

                if (d.saved) {
                    // BlueZ har glemt den. Den skal findes igen foerst --
                    // det er det btcon's connect goer af sig selv.
                    rows.push({ label: "forbind igen", run: act(["connect", mac]) });
                } else {
                    rows.push({
                        label: d.connected ? "afbryd" : "forbind",
                        mark: d.connected ? "●" : "○",
                        color: d.connected ? Theme.color4 : Theme.foreground,
                        run: act([d.connected ? "disconnect" : "connect", mac])
                    });
                    if (!d.paired) rows.push({ label: "par enhed", run: act(["pair", mac]) });
                    rows.push({
                        label: d.trusted ? "stol ikke på" : "stol på",
                        run: act([d.trusted ? "untrust" : "trust", mac])
                    });
                    rows.push({
                        label: d.blocked ? "afblokér" : "bloker",
                        run: act([d.blocked ? "unblock" : "block", mac])
                    });
                    if (d.paired) rows.push({
                        label: "ophæv parring",
                        run: () => bt.run(["remove", mac], () => Menu.back())
                    });
                }

                rows.push({
                    label: "glem",
                    color: Theme.color8,
                    run: () => bt.run(["forget", mac], () => Menu.back())
                });

                Menu.fill(rows);
            })
        };
    }

    function btScanPage(): var {
        return {
            title: "scan + par ny enhed",
            // btcon scan skanner i 12 sekunder. Det er meningen -- en enhed
            // der lige er taendt, dukker ikke op med det samme.
            load: () => bt.run(["scan"], text => {
                Menu.fill(bt.lines(text).map(line => {
                    const mac = line.split(/\s+/)[0];
                    const name = line.slice(mac.length).trim();
                    return {
                        label: name === "" ? mac : name,
                        hint: mac,
                        run: () => bt.run(["pair", mac], () => Menu.back())
                    };
                }));
            })
        };
    }

    // ---- udklipsholder ---------------------------------------------------
    // cliphist gennem fuzzel_clip, samme to kald som dens egen menu bruger.
    // Filterfeltet goer her det samme som fuzzels gjorde: skriv, og listen
    // bliver kortere.
    function clipPage(): var {
        return {
            title: "udklip",
            load: () => clip.run(["list"], text => {
                Menu.fill(clip.lines(text).map(line => {
                    // "id<TAB>tekst" -- id'et skal med tilbage, teksten vises.
                    const tab = line.indexOf("\t");
                    return {
                        label: tab >= 0 ? line.slice(tab + 1) : line,
                        run: () => clip.run(["pick", line], () => Menu.close())
                    };
                }));
            })
        };
    }

    // ---- ydelse ----------------------------------------------------------
    // perf-mode mistede sin klikflade da modulet blev taget ud af baren. Her
    // er den tilbage, med de samme fire valg som dens fuzzel-menu.
    readonly property var perfValg: [
        { navn: "low-power", vist: "spar" },
        { navn: "balanced", vist: "balanceret" },
        { navn: "performance", vist: "fuld" },
        { navn: "auto", vist: "automatisk" }
    ]

    function perfNavn(mode: string): string {
        const hit = root.perfValg.find(v => v.navn === mode);
        if (hit) return hit.vist;
        return mode === "boost" ? "boost" : "automatisk";
    }

    function perfPage(): var {
        return {
            title: "ydelse",
            // Tilstanden kommer fra Perf, som allerede poller. Ingen grund til
            // at spoerge scriptet en gang til.
            load: () => Menu.fill(root.perfValg.map(v => ({
                label: v.vist,
                hint: v.navn,
                mark: Perf.mode === v.navn ? "●" : "○",
                color: Perf.mode === v.navn ? Perf.color : Theme.foreground,
                run: () => perf.run(["set", v.navn], () => Menu.refresh())
            })))
        };
    }

    // ---- sluk ------------------------------------------------------------
    // Handlingerne ligger i `bye`, saa de staar ét sted. Alle tre spoerger
    // igen foerst -- et fejlklik i et hjoerne maa ikke slukke maskinen.
    function slukPage(): var {
        return {
            title: "sluk",
            load: () => Menu.fill([
                {
                    label: "laas skaermen",
                    run: () => Menu.push(root.bekraeftPage("laas skaermen", "lock"))
                },
                {
                    label: "genstart",
                    run: () => Menu.push(root.bekraeftPage("genstart", "reboot"))
                },
                {
                    label: "sluk maskinen",
                    color: Theme.stateBad,
                    run: () => Menu.push(root.bekraeftPage("sluk maskinen", "poweroff"))
                }
            ])
        };
    }

    // ---- root-adgang -----------------------------------------------------
    // Kun adgangskoden, og kun naar fingeraftrykket gav op. Selve
    // spoergsmaalet staar i output-pillen -- det er maskinen der spoerger. Det
    // her er det eneste led hvor Filip skal skrive noget, og det er input, saa
    // det hoerer hjemme i kroppen.
    //
    // Der er ikke noget at vaelge imellem: koden ER svaret. Kommandoen staar
    // ordret over feltet, saa han kan se hvad han giver adgang til, mens han
    // taster. fill() rydder status, saa den skal saettes bagefter.
    function sudoPage(): var {
        return {
            title: "sudo",
            load: () => {
                Menu.fill([]);
                Menu.status = Sudo.cmd;
            }
        };
    }

    function bekraeftPage(hvad: string, handling: string): var {
        return {
            title: hvad + "?",
            load: () => Menu.fill([
                { label: "ja", color: Theme.stateBad, run: () => sys.run([handling], null) },
                { label: "nej", run: () => Menu.back() }
            ])
        };
    }

    Sh { id: nm; script: root.nmScript }
    Sh { id: bt; script: root.btScript }
    Sh { id: perf; script: root.perfScript }
    Sh { id: clip; script: root.clipScript }
    Sh { id: sys; script: root.sysScript }
}
