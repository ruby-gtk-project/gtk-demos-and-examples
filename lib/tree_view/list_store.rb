require 'gtk4'

class ListStoreDemo
  Bug = Data.define(:fixed, :number, :severity, :description)

  BUGS = [
    Bug.new(false, 60_482, 'Normal', 'scrollable notebooks and hidden tabs'),
    Bug.new(false, 60_620, 'Critical', 'gdk_surface_clear_area (gdksurface-win32.c) is not thread-safe'),
    Bug.new(false, 50_214, 'Major', 'Xft support does not clean up correctly'),
    Bug.new(true, 52_877, 'Major', 'GtkFileSelection needs a refresh method. '),
    Bug.new(false, 56_070, 'Normal', "Can't click button after setting in sensitive"),
    Bug.new(true, 56_355, 'Normal', 'GtkLabel - Not all changes propagate correctly'),
    Bug.new(false, 50_055, 'Normal', 'Rework width/height computations for TreeView'),
    Bug.new(false, 58_278, 'Normal', "gtk_dialog_set_response_sensitive () doesn't work"),
    Bug.new(false, 55_767, 'Normal', 'Getters for all setters'),
    Bug.new(false, 56_925, 'Normal', 'Gtkcalender size'),
    Bug.new(false, 56_221, 'Normal', 'Selectable label needs right-click copy menu'),
    Bug.new(true, 50_939, 'Normal', 'Add shift clicking to GtkTextView'),
    Bug.new(false, 6_112, 'Enhancement', 'netscape-like collapsible toolbars'),
    Bug.new(false, 1, 'Normal', 'First bug :=)')
  ].freeze

  COLUMN_FIXED = 0
  COLUMN_NUMBER = 1
  COLUMN_SEVERITY = 2
  COLUMN_DESCRIPTION = 3
  COLUMN_PULSE = 4
  COLUMN_ICON = 5
  COLUMN_ACTIVE = 6
  COLUMN_SENSITIVE = 7

  CHARGING_ICON = 'battery-level-10-charging-symbolic'.freeze
  ICON_ROWS = [1, 3].freeze
  INSENSITIVE_ROW = 3

  INTRO = 'This is the bug list (note: not based on real data, it would be nice ' \
          'to have a nice ODBC interface to bugzilla or so, though).'.freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'List Store'
          win.set_default_size(280, 250)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(intro_label)
          box.append(scrolled_window)

          scrolled_window.tap { |sw| sw.child = tree_view }

          tree_view.tap do |view|
            add_columns(view)
            fixed_renderer.signal_connect('toggled') { |_, path| toggle_fixed(path) }
          end
        end

        pulse_spinner

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.list_store', :default_flags)
  def window = @window ||= Gtk::Window.new
  def intro_label = @intro_label ||= Gtk::Label.new(INTRO)
  def fixed_renderer = @fixed_renderer ||= Gtk::CellRendererToggle.new

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.has_frame = true
      sw.set_policy(:never, :automatic)
    end
  end

  def model
    @model ||= Gtk::ListStore.new(TrueClass, Integer, String, String, Integer, String, TrueClass, TrueClass).tap do |store|
      BUGS.each_with_index do |bug, i|
        store.append.tap do |row|
          row[COLUMN_FIXED] = bug.fixed
          row[COLUMN_NUMBER] = bug.number
          row[COLUMN_SEVERITY] = bug.severity
          row[COLUMN_DESCRIPTION] = bug.description
          row[COLUMN_PULSE] = 0
          row[COLUMN_ICON] = ICON_ROWS.include?(i) ? CHARGING_ICON : nil
          row[COLUMN_ACTIVE] = false
          row[COLUMN_SENSITIVE] = i != INSENSITIVE_ROW
        end
      end
    end
  end

  def tree_view
    @tree_view ||= Gtk::TreeView.new(model).tap do |view|
      view.vexpand = true
      view.search_column = COLUMN_DESCRIPTION
    end
  end

  private

  def add_columns(view)
    Gtk::TreeViewColumn.new('Fixed?', fixed_renderer, active: COLUMN_FIXED).tap do |column|
      column.sizing = :fixed
      column.fixed_width = 50
      view.append_column(column)
    end

    [['Bug number', COLUMN_NUMBER], ['Severity', COLUMN_SEVERITY], ['Description', COLUMN_DESCRIPTION]].each do |title, index|
      Gtk::TreeViewColumn.new(title, Gtk::CellRendererText.new, text: index).tap do |column|
        column.sort_column_id = index
        view.append_column(column)
      end
    end

    Gtk::TreeViewColumn.new('Spinning', Gtk::CellRendererSpinner.new,
                            pulse: COLUMN_PULSE, active: COLUMN_ACTIVE).tap do |column|
      column.sort_column_id = COLUMN_PULSE
      view.append_column(column)
    end

    Gtk::TreeViewColumn.new('Symbolic icon', Gtk::CellRendererPixbuf.new,
                            'icon-name' => COLUMN_ICON, 'sensitive' => COLUMN_SENSITIVE).tap do |column|
      column.sort_column_id = COLUMN_ICON
      view.append_column(column)
    end
  end

  def toggle_fixed(path)
    model.get_iter(Gtk::TreePath.new(path)).tap do |row|
      row[COLUMN_FIXED] = !row[COLUMN_FIXED]
    end
  end

  # Drives the spinner cell in the first row.
  def pulse_spinner
    GLib::Timeout.add(80) do
      model.iter_first.tap do |row|
        row[COLUMN_PULSE] = row[COLUMN_PULSE] + 1
        row[COLUMN_ACTIVE] = true
      end

      GLib::Source::CONTINUE
    end
  end
end

ListStoreDemo.new.build.run
