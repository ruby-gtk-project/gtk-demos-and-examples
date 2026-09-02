require 'gtk4'

# Text does not have to be one flat colour: turning a Pango layout into a
# Cairo path lets it be filled with a gradient and then outlined.
class TextMaskDemo
  TEXT = "Pango power!\nPango power!\nPango power!".freeze
  FONT = 'sans bold 34'.freeze

  RAINBOW = [
    [0.0, 1.0, 0.0, 0.0],
    [0.2, 1.0, 0.0, 0.0],
    [0.3, 1.0, 1.0, 0.0],
    [0.4, 0.0, 1.0, 0.0],
    [0.6, 0.0, 1.0, 1.0],
    [0.7, 0.0, 0.0, 1.0],
    [0.8, 1.0, 0.0, 1.0],
    [1.0, 1.0, 0.0, 1.0]
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Text Mask'
          win.resizable = true
          win.set_size_request(400, 240)
          win.child = drawing_area
        end

        drawing_area.tap { |area| area.set_draw_func { |_, cr, w, h| draw(cr, w, h) } }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.textmask', :default_flags)
  def window = @window ||= Gtk::Window.new
  def drawing_area = @drawing_area ||= Gtk::DrawingArea.new

  private

  def draw(cr, width, height)
    cr.save

    cr.move_to(30, 20)
    cr.pango_layout_path(layout)

    Cairo::LinearPattern.new(0.0, 0.0, width, height).tap do |pattern|
      RAINBOW.each { |offset, red, green, blue| pattern.add_color_stop_rgb(offset, red, green, blue) }
      cr.set_source(pattern)
      cr.fill_preserve
    end

    cr.set_source_rgb(0.0, 0.0, 0.0)
    cr.set_line_width(0.5)
    cr.stroke

    cr.restore
  end

  def layout
    @layout ||= drawing_area.create_pango_layout(TEXT).tap do |l|
      l.font_description = Pango::FontDescription.new(FONT)
    end
  end
end

TextMaskDemo.new.build.run
