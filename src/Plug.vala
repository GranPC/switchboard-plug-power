namespace Power {

	GLib.Settings settings;
	Granite.Widgets.StaticNotebook staticnotebook;
	
	class ComboBox : Gtk.ComboBoxText {
	
		public Gtk.Label label;
		private string key;
		
		// this maps combobox indices to gsettings enums
		private int[] map_to_sett = {1, 2, 3, 4, 5};
		// and vice-versa
		private int[] map_to_list = {4, 0, 1, 2, 3, 4};
		
		public ComboBox (string label, string key) {
			this.key = key;
			this.label = new Gtk.Label (label);
			this.label.halign = Gtk.Align.END;

			this.append_text (_("Suspend"));
			this.append_text (_("Shutdown"));
			this.append_text (_("Hibernate"));
			this.append_text (_("Ask me"));
			this.append_text (_("Do nothing"));
		
			this.hexpand = true;
		
			update_combo ();
		
			this.changed.connect (update_settings);
			settings.changed[key].connect (update_combo);
		}

		private void update_settings () {
			settings.set_enum (key, map_to_sett[active]);
		}
	
		private void update_combo () {
			int val = settings.get_enum (key);
			active = map_to_list [val];
		}
	}
	
	public class Plug : Switchboard.Plug {
	
		public Plug () {
			Object (category: Category.HARDWARE,
				code_name: "system-pantheon-power",
				display_name: _("Power"),
				description: _("Shows Power Settings…"),
				icon: "preferences-system-power");

			settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");

		}

		public override Gtk.Widget get_widget () {
			if (staticnotebook == null) {
				//setup_info ();
				setup_ui ();
			}
			return staticnotebook;
		}

		public override void shown () {
		
		}
		
		public override void hidden () {
		
		}
		
		public override void search_callback (string location) {
		
		}
		
		// 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
		public override async Gee.TreeMap<string, string> search (string search) {
			return new Gee.TreeMap<string, string> (null, null);
		}

		void setup_ui () {
			staticnotebook = new Granite.Widgets.StaticNotebook (false);
			var plug_grid = create_notebook_pages ("ac");
			var battery_grid = create_notebook_pages ("battery");
		
			staticnotebook.append_page (plug_grid, new Gtk.Label(_("Plugged In")));
			staticnotebook.append_page (battery_grid, new Gtk.Label(_("Battery Power")));
			staticnotebook.margin = 12;
			staticnotebook.show_all ();
		}
	
		private Gtk.Grid create_notebook_pages (string type) {
			var grid = new Gtk.Grid ();
			grid.margin = 12;
			grid.column_spacing = 12;
			grid.row_spacing = 12;

			var scale_label = new Gtk.Label (_("Put the computer to sleep when inactive:"));
			var scale_settings = @"sleep-inactive-$type-timeout";
			
			var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 4000, 300);
			scale.set_draw_value (false);
			scale.add_mark (300, Gtk.PositionType.BOTTOM, _("5 min"));
			scale.add_mark (600, Gtk.PositionType.BOTTOM, _("10 min"));
			scale.add_mark (1800, Gtk.PositionType.BOTTOM, _("30 min"));
			scale.add_mark (3600, Gtk.PositionType.BOTTOM, _("1 hour"));
			scale.add_mark (4000, Gtk.PositionType.BOTTOM, _("Never"));
			scale.hexpand = true;
			scale.width_request = 480;
		
			var dval = (double) settings.get_int (scale_settings);
		
			if (dval == 0)
				scale.set_value (4000);
			else
				scale.set_value (dval);
		
			scale.value_changed.connect (() => {
				var val = (int) scale.get_value ();
				if (val <= 3600)
					settings.set_int (scale_settings, val);
				else if (val == 4000)
					settings.set_int (scale_settings, 0);
			});
		
			grid.attach (scale_label, 0, 0, 1, 1);
			grid.attach (scale, 1, 0, 1, 1);
		
			var lid_closed_box = new ComboBox (_("When the lid is closed:"), @"lid-close-$type-action");
			grid.attach (lid_closed_box.label, 0, 1, 1, 1);
			grid.attach (lid_closed_box, 1, 1, 1, 1);
			
			if (type != "ac") {
				var critical_box = new ComboBox (_("When battery power is critically low:"), "critical-battery-action");
				grid.attach (critical_box.label, 0, 2, 1, 1);
				grid.attach (critical_box, 1, 2, 1, 1);
			}
			
			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			separator.vexpand = true;
			separator.valign = Gtk.Align.END;
			grid.attach (separator, 0, 3, 2, 1);
			
			string[] labels = {_("Sleep button:"), _("Suspend button:"), _("Hibernate button:"), _("Power button:")};
			string[] keys = {"button-sleep", "button-suspend", "button-hibernate", "button-power"};

			for (int i = 0; i < labels.length; i++) {
				var box = new Power.ComboBox (labels[i], keys[i]);
				grid.attach (box.label, 0, i+4, 1, 1);
				grid.attach (box, 1, i+4, 1, 1);
			}
			
			return grid;
		}
	}
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Power plug");
    var plug = new Power.Plug ();
    return plug;
}