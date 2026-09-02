require 'gtk4'

# Gtk::Svg shows an SVG in a Gtk::Picture, so it scales with the window.
# Path animations (.gpa files) carry several states; clicking the picture
# steps through them.
class SvgPaintableDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze
  DEFAULT_SVG = 'org.gtk.gtk4.NodeEditor.Devel.svg'.freeze
  # GTK_SVG_STATE_EMPTY is (guint) -1, which the bindings do not export.
  EMPTY_STATE = (2**32) - 1

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Paintable — SVG'
          win.set_default_size(330, 330)
          win.titlebar = header_bar
          win.child = picture
        end

        header_bar.tap do |header|
          header.pack_start(open_button)
          open_button.signal_connect('clicked') { choose_file }
        end

        picture.tap do |p|
          p.paintable = svg(File.join(ASSETS, DEFAULT_SVG))
          p.add_controller(click_gesture)
        end

        click_gesture.tap { |gesture| gesture.signal_connect('pressed') { next_state } }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paintable_svg', :default_flags)
  def window = @window ||= Gtk::Window.new
  def header_bar = @header_bar ||= Gtk::HeaderBar.new
  def click_gesture = @click_gesture ||= Gtk::GestureClick.new
  def picture = @picture ||= Gtk::Picture.new.tap { |p| p.set_size_request(16, 16) }

  def open_button
    @open_button ||= Gtk::Button.new(label: '_Open').tap { |btn| btn.use_underline = true }
  end

  def svg_filter
    @svg_filter ||= Gtk::FileFilter.new.tap do |filter|
      filter.add_mime_type('image/svg+xml')
      filter.add_mime_type('image/x-gtk-path-animation')
      filter.add_pattern('*.gpa')
    end
  end

  private

  def svg(path)
    Gtk::Svg.new.tap { |s| s.load_from_bytes(GLib::Bytes.new(File.binread(path))) }
  end

  # The C demo walks through every state the file declares. The Ruby
  # bindings expose neither gtk_svg_get_n_states nor a working
  # state_names, so clicking toggles the first state on and off instead.
  def next_state
    picture.paintable.tap do |paintable|
      paintable.state = paintable.state == EMPTY_STATE ? 0 : EMPTY_STATE
    end
  end

  def choose_file
    Gtk::FileDialog.new.tap do |dialog|
      dialog.title = 'Open svg image'
      dialog.filters = Gio::ListStore.new(Gtk::FileFilter.gtype).tap { |list| list.append(svg_filter) }

      dialog.open(window, nil) do |source, result|
        source.open_finish(result).then { |file| picture.paintable = svg(file.path) if file }
      rescue GLib::Error
        nil
      end
    end
  end
end

SvgPaintableDemo.new.build.run
