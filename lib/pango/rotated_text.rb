require 'gtk4'

# PangoCairo drawing text around a circle, next to a plain label showing the
# same string.
#
# The C demo also installs a custom PangoCairo shape renderer that draws the
# heart with cairo instead of using the glyph. pango_cairo_context_set_shape_
# renderer is not exposed by the Ruby bindings, so the heart here is the
# ordinary U+2665 character.
class RotatedTextDemo
  TEXT = 'I ♥ GTK'.freeze
  FONT = 'Serif 18'.freeze
  RADIUS = 150
  WORDS = 5

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Rotated Text'
          win.set_default_size(4 * RADIUS, 2 * RADIUS)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(drawing_area)
          box.append(label)

          drawing_area.tap { |area| area.set_draw_func { |_, cr, w, h| draw(cr, w, h) } }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.rotated_text', :default_flags)
  def window = @window ||= Gtk::Window.new
  def label = @label ||= Gtk::Label.new(TEXT)

  def content_box
    @content_box ||= Gtk::Box.new(:horizontal, 0).tap { |box| box.homogeneous = true }
  end

  def drawing_area
    @drawing_area ||= Gtk::DrawingArea.new.tap { |area| area.add_css_class('view') }
  end

  private

  # User space is set up so the centred square runs from -RADIUS to RADIUS in
  # both directions, whatever size the widget happens to be.
  def draw(cr, width, height)
    ([width, height].min / 2.0).then do |device_radius|
      cr.translate(device_radius + ((width - (2 * device_radius)) / 2),
                   device_radius + ((height - (2 * device_radius)) / 2))
      cr.scale(device_radius / RADIUS, device_radius / RADIUS)
    end

    Cairo::LinearPattern.new(-RADIUS, -RADIUS, RADIUS, RADIUS).tap do |pattern|
      pattern.add_color_stop_rgb(0.0, 0.5, 0.0, 0.0)
      pattern.add_color_stop_rgb(1.0, 0.0, 0.0, 0.5)
      cr.set_source(pattern)
    end

    layout(cr).tap do |l|
      WORDS.times do
        cr.update_pango_layout(l)
        cr.move_to(-l.pixel_size.first / 2, -RADIUS * 0.9)
        cr.show_pango_layout(l)
        cr.rotate(Math::PI * 2 / WORDS)
      end
    end
  end

  def layout(cr)
    cr.create_pango_layout.tap do |l|
      l.text = TEXT
      l.font_description = Pango::FontDescription.new(FONT)
    end
  end
end

RotatedTextDemo.new.build.run
