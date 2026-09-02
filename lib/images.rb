require 'gtk4'

# GdkPixbuf decodes an animated GIF into a stream of frames, but nothing in
# GTK turns that into a paintable, so this drives a Gtk::Picture by hand:
# every frame becomes a texture and is handed to the picture on a timer.
class GifAnimation
  def initialize(path)
    @animation = GdkPixbuf::PixbufAnimation.new(path)
  end

  def build
    @build ||= picture.tap do
      show_frame
      schedule_next
    end
  end

  def picture = @picture ||= Gtk::Picture.new
  def iterator = @iterator ||= @animation.get_iter

  private

  def show_frame = picture.paintable = Gdk::Texture.new(iterator.pixbuf)

  def schedule_next
    GLib::Timeout.add([iterator.delay_time, 20].max) do
      iterator.advance
      show_frame
      schedule_next
      GLib::Source::REMOVE
    end
  end
end

class ImagesDemo
  ASSETS = File.expand_path('../demos/gtk-demo', __dir__).freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Images'
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(columns_box)
          box.append(insensitive_button)

          columns_box.tap do |columns|
            columns.append(resources_column)
            columns.append(animations_column)
            columns.append(video_column)
            columns.append(paintable_column)
          end

          resources_column.tap do |column|
            column.append(heading('Image from a resource'))
            column.append(centred(resource_image))
            column.append(heading('Animation from a resource'))
            column.append(centred(gif_animation.build))
            column.append(heading('Symbolic themed icon'))
            column.append(centred(symbolic_image))
          end

          animations_column.tap do |column|
            column.append(heading('Stateful icon'))
            column.append(centred(stateful_image))
            column.append(state_switch)
            column.append(heading('Path animation'))
            column.append(centred(animated_image))
          end

          video_column.tap do |column|
            column.append(heading('Displaying video'))
            column.append(centred(video))
          end

          paintable_column.tap do |column|
            column.append(heading('GtkWidgetPaintable'))
            column.append(mirror_picture)
          end

          state_switch.tap do |sw|
            sw.bind_property('active', stateful_svg, 'state', :default)
          end

          insensitive_button.tap do |btn|
            btn.signal_connect('toggled') { toggle_sensitivity(btn.active?) }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.images', :default_flags)
  def window = @window ||= Gtk::Window.new
  def columns_box = @columns_box ||= Gtk::Box.new(:horizontal, 16)
  def resources_column = @resources_column ||= Gtk::Box.new(:vertical, 8)
  def animations_column = @animations_column ||= Gtk::Box.new(:vertical, 8)
  def video_column = @video_column ||= Gtk::Box.new(:vertical, 8)
  def paintable_column = @paintable_column ||= Gtk::Box.new(:vertical, 8)
  def gif_animation = @gif_animation ||= GifAnimation.new(File.join(ASSETS, 'floppybuddy.gif'))
  def stateful_svg = @stateful_svg ||= svg('stateful.gpa')
  def animated_svg = @animated_svg ||= svg('animated.gpa')
  def stateful_image = @stateful_image ||= svg_image(stateful_svg)
  def animated_image = @animated_image ||= svg_image(animated_svg)
  def state_switch = @state_switch ||= Gtk::Switch.new.tap { |sw| sw.halign = :start }

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 16
      box.margin_end = 16
      box.margin_top = 16
      box.margin_bottom = 16
    end
  end

  def resource_image
    @resource_image ||= Gtk::Image.new(file: File.join(ASSETS, 'data/scalable/apps/org.gtk.Demo4.svg')).tap do |image|
      image.icon_size = :large
    end
  end

  def symbolic_image
    @symbolic_image ||= Gtk::Image.new(icon: Gio::ThemedIcon.new('battery-level-10-charging-symbolic')).tap do |image|
      image.icon_size = :large
    end
  end

  # Needs a working GTK media backend (GStreamer with the base and good
  # plugins). Run with GTK_MEDIA=none on machines that lack one.
  def video
    @video ||= Gtk::Video.new(File.join(ASSETS, 'gtk-logo.webm')).tap { |v| v.loop = true }
  end

  # A live picture of this very window, redrawn as the window changes.
  def mirror_picture
    @mirror_picture ||= Gtk::Picture.new.tap do |picture|
      picture.paintable = Gtk::WidgetPaintable.new(window)
      picture.set_size_request(100, 100)
      picture.valign = :start
    end
  end

  def insensitive_button
    @insensitive_button ||= Gtk::ToggleButton.new(label: '_Insensitive').tap do |btn|
      btn.use_underline = true
      btn.halign = :end
      btn.valign = :end
      btn.vexpand = true
    end
  end

  private

  def heading(text) = Gtk::Label.new(text).tap { |label| label.add_css_class('heading') }

  def centred(child)
    Gtk::Frame.new.tap do |frame|
      frame.halign = :center
      frame.valign = :center
      frame.child = child
    end
  end

  def svg(file)
    Gtk::Svg.new.tap do |s|
      s.load_from_bytes(GLib::Bytes.new(File.binread(File.join(ASSETS, file))))
      s.play
      s.state = 0
    end
  end

  def svg_image(paintable)
    Gtk::Image.new(paintable: paintable).tap { |image| image.pixel_size = 128 }
  end

  def toggle_sensitivity(insensitive)
    columns_box.sensitive = !insensitive
  end
end

ImagesDemo.new.build.run
