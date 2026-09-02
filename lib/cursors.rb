require 'gtk4'

class CursorsDemo
  ASSETS = File.expand_path('../demos/gtk-demo', __dir__).freeze

  CSS = '.cursorbg { background: linear-gradient(to bottom right, white 0%, white 50%, black 50%, black 100%); }'.freeze

  # name, image source, hotspot x, hotspot y. A source starting with "/" is a
  # resource GTK itself ships; anything else is a file in the demo assets.
  CURSORS = [
    ['default', '/org/gtk/libgdk/cursor/default', 5, 5],
    ['none', 'none_cursor.png', 0, 0],
    ['gtk-logo', 'gtk_logo_cursor.png', 18, 2],
    ['context-menu', '/org/gtk/libgdk/cursor/context-menu', 5, 5],
    ['help', '/org/gtk/libgdk/cursor/help', 16, 27],
    ['pointer', '/org/gtk/libgdk/cursor/pointer', 14, 9],
    ['progress', '/org/gtk/libgdk/cursor/progress', 5, 4],
    ['wait', '/org/gtk/libgdk/cursor/wait', 11, 11],
    ['cell', '/org/gtk/libgdk/cursor/cell', 15, 15],
    ['crosshair', '/org/gtk/libgdk/cursor/crosshair', 15, 15],
    ['text', '/org/gtk/libgdk/cursor/text', 14, 15],
    ['vertical-text', '/org/gtk/libgdk/cursor/vertical-text', 16, 15],
    ['alias', '/org/gtk/libgdk/cursor/alias', 12, 11],
    ['copy', '/org/gtk/libgdk/cursor/copy', 12, 11],
    ['move', '/org/gtk/libgdk/cursor/move', 12, 11],
    ['dnd-ask', '/org/gtk/libgdk/cursor/dnd-ask', 12, 11],
    ['no-drop', '/org/gtk/libgdk/cursor/no-drop', 12, 11],
    ['not-allowed', '/org/gtk/libgdk/cursor/not-allowed', 12, 11],
    ['grab', '/org/gtk/libgdk/cursor/grab', 10, 6],
    ['grabbing', '/org/gtk/libgdk/cursor/grabbing', 15, 14],
    ['all-scroll', '/org/gtk/libgdk/cursor/all-scroll', 15, 15],
    ['all-resize', '/org/gtk/libgdk/cursor/all-resize', 15, 15],
    ['col-resize', '/org/gtk/libgdk/cursor/col-resize', 16, 15],
    ['row-resize', '/org/gtk/libgdk/cursor/row-resize', 15, 17],
    ['n-resize', '/org/gtk/libgdk/cursor/n-resize', 17, 7],
    ['e-resize', '/org/gtk/libgdk/cursor/e-resize', 25, 17],
    ['s-resize', '/org/gtk/libgdk/cursor/s-resize', 17, 23],
    ['w-resize', '/org/gtk/libgdk/cursor/w-resize', 8, 17],
    ['ne-resize', '/org/gtk/libgdk/cursor/ne-resize', 20, 13],
    ['nw-resize', '/org/gtk/libgdk/cursor/nw-resize', 13, 13],
    ['se-resize', '/org/gtk/libgdk/cursor/se-resize', 19, 19],
    ['sw-resize', '/org/gtk/libgdk/cursor/sw-resize', 13, 19],
    ['ew-resize', '/org/gtk/libgdk/cursor/ew-resize', 16, 15],
    ['ns-resize', '/org/gtk/libgdk/cursor/ns-resize', 15, 17],
    ['nesw-resize', '/org/gtk/libgdk/cursor/nesw-resize', 14, 14],
    ['nwse-resize', '/org/gtk/libgdk/cursor/nwse-resize', 14, 14],
    ['zoom-in', '/org/gtk/libgdk/cursor/zoom-in', 14, 13],
    ['zoom-out', '/org/gtk/libgdk/cursor/zoom-out', 14, 13]
  ].freeze

  # The first frame introduces the idea; the rest of the CSS cursors follow.
  INTRO_COUNT = 3

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Cursors'
          win.set_default_size(300, 300)
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = content_box }

        content_box.tap do |box|
          box.append(intro_frame)
          box.append(rest_frame)

          intro_frame.tap { |f| f.child = intro_list }
          rest_frame.tap { |f| f.child = rest_list }

          intro_list.tap { |list| CURSORS.first(INTRO_COUNT).each { |c| list.append(cursor_row(*c)) } }
          rest_list.tap { |list| CURSORS.drop(INTRO_COUNT).each { |c| list.append(cursor_row(*c)) } }
        end

        Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, 800)

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.cursors', :default_flags)
  def window = @window ||= Gtk::Window.new
  def intro_frame = @intro_frame ||= Gtk::Frame.new
  def rest_frame = @rest_frame ||= Gtk::Frame.new.tap { |f| f.hexpand = true }
  def intro_list = @intro_list ||= cursor_list
  def rest_list = @rest_list ||= cursor_list
  def provider = @provider ||= Gtk::CssProvider.new.tap { |p| p.load(string: CSS) }

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.hscrollbar_policy = :never
      sw.propagate_natural_height = true
      sw.hexpand = true
    end
  end

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 10).tap do |box|
      box.margin_start = 60
      box.margin_end = 60
      box.margin_top = 60
      box.margin_bottom = 60
      box.halign = :center
    end
  end

  private

  def cursor_list
    Gtk::ListBox.new.tap do |list|
      list.selection_mode = :none
      list.add_css_class('view')
    end
  end

  # Each row shows the cursor's own image, its name, and four swatches:
  # the named cursor, an image cursor, and each falling back to the other.
  def cursor_row(name, source, hotspot_x, hotspot_y)
    texture(source).then do |image_texture|
      Gdk::Cursor.new(name).then do |named|
        Gdk::Cursor.new(image_texture, hotspot_x, hotspot_y).then do |image_cursor|
          Gtk::ListBoxRow.new.tap do |row|
            row.activatable = false
            row.child = Gtk::Box.new(:horizontal, 10).tap do |box|
              box.margin_start = 10
              box.margin_end = 10
              box.margin_top = 10
              box.margin_bottom = 10
              box.append(Gtk::Image.new(paintable: image_texture))
              box.append(row_label(name))
              box.append(swatch(named, "The \"#{name}\" named cursor"))
              box.append(swatch(image_cursor, 'An image cursor'))
              box.append(swatch(Gdk::Cursor.new(name, image_cursor),
                                "The \"#{name}\" named cursor falling back to an image cursor"))
              box.append(swatch(Gdk::Cursor.new(image_texture, hotspot_x, hotspot_y, named),
                                "An image cursor falling back to the \"#{name}\" cursor"))
            end
          end
        end
      end
    end
  end

  def row_label(name)
    Gtk::Label.new(name).tap do |label|
      label.halign = :start
      label.valign = :baseline_fill
      label.xalign = 0.0
      label.hexpand = true
    end
  end

  def swatch(cursor, tooltip)
    Gtk::Frame.new.tap do |frame|
      frame.width_request = 32
      frame.height_request = 32
      frame.cursor = cursor
      frame.tooltip_text = tooltip
      frame.add_css_class('cursorbg')
    end
  end

  def texture(source)
    if source.start_with?('/')
      Gdk::Texture.new(Gio::Resources.lookup_data(source))
    else
      Gdk::Texture.new(Gio::File.new_for_path(File.join(ASSETS, source)))
    end
  end
end

CursorsDemo.new.build.run
