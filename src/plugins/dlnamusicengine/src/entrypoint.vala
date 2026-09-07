using GLib;
using GUPnP;

using Vesper.Core.Plugins;
using Vesper.Core.Settings;

namespace Vesper.Plugins.DLNA {

    public sealed class DlnaMusicEngine :
        GLib.Object,
        Vesper.Core.Plugins.Plugin,
        MusicEngine,
        ConfigurablePlugin {

        private const string AV_TRANSPORT =
            "urn:schemas-upnp-org:service:AVTransport:1";

        private const string RENDERING_CONTROL =
            "urn:schemas-upnp-org:service:RenderingControl:1";

        private GUPnP.Context? context = null;
        private GUPnP.ControlPoint? av_transport_control_point = null;
        private GUPnP.ControlPoint? rendering_control_point = null;

        private GUPnP.ServiceProxy? av_transport = null;
        private GUPnP.ServiceProxy? rendering_control = null;

        private string? source_uri = null;

        private double volume = 1.0;

        private PlaybackState playback_state =
            PlaybackState.STOPPED;

        private int64 position = 0;
        private int64 duration = 0;

        private uint position_timer = 0;

        public PluginKey key {
            owned get {
                return new PluginKey("dlna-1", "DLNA");
            }
        }

        public DlnaMusicEngine () {
            try {
                context = new GUPnP.Context (null, 0);
            } catch (GLib.Error e) {
                warning (
                    "Failed to create GUPnP context: %s",
                    e.message
                );

                return;
            }

            av_transport_control_point =
                new GUPnP.ControlPoint (
                    context,
                    AV_TRANSPORT
                );

            av_transport_control_point.service_proxy_available.connect (
                on_av_transport_available
            );

            av_transport_control_point.set_active (true);

            rendering_control_point =
                new GUPnP.ControlPoint (
                    context,
                    RENDERING_CONTROL
                );

            rendering_control_point.service_proxy_available.connect (
                on_rendering_control_available
            );

            rendering_control_point.set_active (true);

            start_position_timer ();
        }

        ~DlnaMusicEngine () {
            stop_position_timer ();

            if (av_transport_control_point != null) {
                av_transport_control_point.set_active (false);
            }

            if (rendering_control_point != null) {
                rendering_control_point.set_active (false);
            }

            stop_player ();
        }

        public void configure (SettingsEngine settings) {
        }

        public void set_source (string uri) {
            source_uri = uri;

            if (av_transport == null) {
                warning ("No DLNA renderer is currently available");

                return;
            }

            stop_player ();

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "SetAVTransportURI"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                action.add_argument (
                    "CurrentURI",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "CurrentURI",
                    uri
                );

                action.add_argument (
                    "CurrentURIMetaData",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "CurrentURIMetaData",
                    ""
                );

                av_transport.call_action (
                    action,
                    null
                );

                set_playback_state (
                    PlaybackState.STOPPED
                );

                position = 0;
                duration = 0;

            } catch (GLib.Error e) {
                warning (
                    "Failed to set DLNA source: %s",
                    e.message
                );

                set_playback_state (
                    PlaybackState.STOPPED
                );
            }
        }

        public bool has_player () {
            return av_transport != null;
        }

        public PlaybackState get_state () {
            return playback_state;
        }

        public int64 get_position () {
            return position;
        }

        public int64 get_duration () {
            return duration;
        }

        public void stop_player () {
            stop_position_timer ();

            if (av_transport == null) {
                set_playback_state (
                    PlaybackState.STOPPED
                );

                return;
            }

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "Stop"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                av_transport.call_action (
                    action,
                    null
                );

            } catch (GLib.Error e) {
                warning (
                    "Failed to stop DLNA renderer: %s",
                    e.message
                );
            }

            set_playback_state (
                PlaybackState.STOPPED
            );
        }

        public bool start_player () {
            if (av_transport == null) {
                warning ("No DLNA renderer available");

                return false;
            }

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "Play"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                action.add_argument (
                    "Speed",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "Speed",
                    "1"
                );

                av_transport.call_action (
                    action,
                    null
                );

                start_position_timer ();

                return true;

            } catch (GLib.Error e) {
                warning (
                    "Failed to start DLNA playback: %s",
                    e.message
                );

                set_playback_state (
                    PlaybackState.STOPPED
                );

                return false;
            }
        }

        public void pause_player () {
            if (av_transport == null) {
                return;
            }

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "Pause"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                av_transport.call_action (
                    action,
                    null
                );

            } catch (GLib.Error e) {
                warning (
                    "Failed to pause DLNA playback: %s",
                    e.message
                );
            }
        }

        public void seek (int64 position) {
            if (av_transport == null) {
                return;
            }

            int64 seconds = position / TimeSpan.SECOND;

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "Seek"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                action.add_argument (
                    "Unit",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "Unit",
                    "REL_TIME"
                );

                action.add_argument (
                    "Target",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "Target",
                    format_time (seconds)
                );

                av_transport.call_action (
                    action,
                    null
                );

            } catch (GLib.Error e) {
                warning (
                    "Failed to seek DLNA playback: %s",
                    e.message
                );
            }
        }

        public void set_volume (double volume) {
            this.volume =
                Math.fmin (
                    1.0,
                    Math.fmax (0.0, volume)
                );

            if (rendering_control == null) {
                return;
            }

            uint volume_value =
                (uint) Math.round (this.volume * 100.0);

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "SetVolume"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                action.add_argument (
                    "Channel",
                    new GLib.Value (typeof (string))
                );

                action.set (
                    "Channel",
                    "Master"
                );

                action.add_argument (
                    "DesiredVolume",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "DesiredVolume",
                    volume_value
                );

                rendering_control.call_action (
                    action,
                    null
                );

            } catch (GLib.Error e) {
                warning (
                    "Failed to set DLNA volume: %s",
                    e.message
                );
            }
        }

        public double get_volume () {
            return volume;
        }

        private void on_av_transport_available (
            GUPnP.ControlPoint control_point,
            GUPnP.ServiceProxy proxy
        ) {
            if (av_transport != null) {
                return;
            }

            message (
                "Found DLNA renderer: %s",
                proxy.get_udn ()
            );

            av_transport = proxy;

            set_playback_state (
                PlaybackState.STOPPED
            );
        }

        private void on_rendering_control_available (
            GUPnP.ControlPoint control_point,
            GUPnP.ServiceProxy proxy
        ) {
            if (rendering_control != null) {
                return;
            }

            rendering_control = proxy;

            message (
                "Found DLNA rendering control: %s",
                proxy.get_udn ()
            );
        }

        private void start_position_timer () {
            stop_position_timer ();

            position_timer =
                Timeout.add (
                    1000,
                    update_position
                );
        }

        private void stop_position_timer () {
            if (position_timer == 0) {
                return;
            }

            Source.remove (position_timer);

            position_timer = 0;
        }

        private bool update_position () {
            if (av_transport == null) {
                return Source.CONTINUE;
            }

            try {
                var action = new GUPnP.ServiceProxyAction (
                    "GetPositionInfo"
                );

                action.add_argument (
                    "InstanceID",
                    new GLib.Value (typeof (uint))
                );

                action.set (
                    "InstanceID",
                    0
                );

                av_transport.call_action (
                    action,
                    null
                );

                string track_duration = "";
                string rel_time = "";

                GLib.Error? error = null;

                action.get_result (
                    out error,
                    "TrackDuration",
                    typeof (string),
                    out track_duration,
                    "RelTime",
                    typeof (string),
                    out rel_time
                );

                if (error != null) {
                    warning (
                        "Failed to read DLNA position: %s",
                        error.message
                    );

                    return Source.CONTINUE;
                }

                duration =
                    parse_time (track_duration);

                position =
                    parse_time (rel_time);

                this.position_changed (
                    position,
                    duration
                );

            } catch (GLib.Error e) {
                warning (
                    "Failed to query DLNA position: %s",
                    e.message
                );
            }

            return Source.CONTINUE;
        }

        private void set_playback_state (
            PlaybackState state
        ) {
            if (playback_state == state) {
                return;
            }

            playback_state = state;

            this.state_changed (state);
        }

        private static int64 parse_time (string value) {
            string[] parts = value.split (":");

            if (parts.length != 3) {
                return 0;
            }

            int64 hours = int64.parse (parts[0]);
            int64 minutes = int64.parse (parts[1]);
            double seconds = double.parse (parts[2]);

            double total_seconds =
                (hours * 3600.0) +
                (minutes * 60.0) +
                seconds;

            return (int64) (
                total_seconds * TimeSpan.SECOND
            );
        }

        private static string format_time (int64 seconds) {
            int64 hours = seconds / 3600;
            int64 minutes = (seconds % 3600) / 60;
            int64 remaining = seconds % 60;

            return "%02lld:%02lld:%02lld".printf (
                hours,
                minutes,
                remaining
            );
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    Peas.ObjectModule object_module =
        module as Peas.ObjectModule;

    object_module.register_extension_type (
        typeof (MusicEngine),
        typeof (Vesper.Plugins.DLNA.DlnaMusicEngine)
    );
}