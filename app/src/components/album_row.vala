using Gtk;
using PiPod.Core.Models;

namespace PiPod.Components {
    public class AlbumRow : Button {
        public Album album { get; construct; }

        public signal void selected (Album album);

        public AlbumRow (
            Album album
        ) {
            Object (
                album: album
            );

            halign =
                Align.FILL;

            hexpand = true;

            has_frame = false;

            tooltip_text =
                album.display_name ();

            var row =
                new Box (
                    Orientation.HORIZONTAL,
                    12
                );

            row.set_margin_top (8);
            row.set_margin_bottom (8);
            row.set_margin_start (12);
            row.set_margin_end (12);

            var icon =
                new Image.from_icon_name (
                    "media-optical-audio-symbolic"
                );

            icon.pixel_size = 20;

            row.append (
                icon
            );

            var label =
                new Label (
                    album.display_name ()
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
                    album
                );
            });
        }
    }
}