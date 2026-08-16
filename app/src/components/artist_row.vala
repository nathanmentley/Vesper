using Gtk;
using PiPod.Core.Models;

namespace PiPod.Components {
    public class ArtistRow : Button {
        public Artist artist { get; construct; }

        public signal void selected (Artist artist);

        public ArtistRow (
            Artist artist
        ) {
            Object (
                artist: artist
            );

            halign =
                Align.FILL;

            hexpand = true;

            has_frame = false;

            tooltip_text =
                artist.name;

            /*
             * ---------------------------------------------------------
             * Row
             * ---------------------------------------------------------
             */

            var row =
                new Box (
                    Orientation.HORIZONTAL,
                    12
                );

            row.set_margin_top (8);
            row.set_margin_bottom (8);
            row.set_margin_start (12);
            row.set_margin_end (12);

            /*
             * Icon
             */

            var icon =
                new Image.from_icon_name (
                    "system-users-symbolic"
                );

            icon.pixel_size = 20;

            row.append (
                icon
            );

            /*
             * Name
             */

            var label =
                new Label (
                    artist.name
                );

            label.halign =
                Align.START;

            label.hexpand =
                true;

            label.ellipsize =
                Pango.EllipsizeMode.END;

            row.append (
                label
            );

            /*
             * Arrow
             */

            var arrow =
                new Image.from_icon_name (
                    "go-next-symbolic"
                );

            arrow.add_css_class (
                "dim-label"
            );

            row.append (
                arrow
            );

            set_child (
                row
            );

            clicked.connect (() => {
                selected (
                    artist
                );
            });
        }
    }
}