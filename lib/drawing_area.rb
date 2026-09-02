require 'gtk4'

class DrawingAreaDemo
  CHECK_SIZE = 16
  BRUSH_WIDTH = 6

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Drawing Area'
          win.set_default_size(250, -1)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(groups_label)
          box.append(groups_frame)
          box.append(scribble_label)
          box.append(scribble_frame)

          groups_frame.tap { |frame| frame.child = groups_area }
          scribble_frame.tap { |frame| frame.child = scribble_area }

          groups_area.tap { |area| area.set_draw_func { |_, cr, w, h| draw_groups(cr, w, h) } }

          scribble_area.tap do |area|
            area.set_draw_func { |_, cr, _, _| draw_scribble(cr) }
            area.signal_connect('resize') { create_surface }
            area.add_controller(drag_gesture)
          end

          drag_gesture.tap do |drag|
            drag.signal_connect('drag-begin') { |_, x, y| begin_stroke(x, y) }
            drag.signal_connect('drag-update') { |_, dx, dy| extend_stroke(dx, dy) }
            drag.signal_connect('drag-end') { |_, dx, dy| extend_stroke(dx, dy) }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.drawing_area', :default_flags)
  def window = @window ||= Gtk::Window.new
  def groups_label = @groups_label ||= heading('Knockout groups')
  def scribble_label = @scribble_label ||= heading('Scribble area')
  def groups_frame = @groups_frame ||= expanding_frame
  def scribble_frame = @scribble_frame ||= expanding_frame
  def groups_area = @groups_area ||= drawing_area
  def scribble_area = @scribble_area ||= drawing_area

  # Button 0 means "any button".
  def drag_gesture = @drag_gesture ||= Gtk::GestureDrag.new.tap { |drag| drag.button = 0 }

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 16
      box.margin_end = 16
      box.margin_top = 16
      box.margin_bottom = 16
    end
  end

  private

  def heading(text) = Gtk::Label.new(text).tap { |label| label.add_css_class('heading') }
  def expanding_frame = Gtk::Frame.new.tap { |frame| frame.vexpand = true }

  def drawing_area
    Gtk::DrawingArea.new.tap do |area|
      area.accessible_role = :img
      area.content_width = 100
      area.content_height = 100
    end
  end

  # -- Scribble area ------------------------------------------------------
  # Strokes are kept on an image surface so they survive redraws; resizing
  # the window makes a fresh surface and so clears the drawing.

  def create_surface
    @surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, scribble_area.width, scribble_area.height)

    Cairo::Context.new(@surface).tap do |cr|
      cr.set_source_rgb(1, 1, 1)
      cr.paint
      cr.destroy
    end
  end

  def surface
    create_surface if @surface.nil? ||
                      @surface.width != scribble_area.width ||
                      @surface.height != scribble_area.height
    @surface
  end

  def draw_scribble(cr)
    cr.set_source(surface, 0, 0)
    cr.paint
  end

  def begin_stroke(x, y)
    @start_x = x
    @start_y = y
    draw_brush(x, y)
  end

  def extend_stroke(dx, dy) = draw_brush(@start_x + dx, @start_y + dy)

  def draw_brush(x, y)
    Cairo::Context.new(surface).tap do |cr|
      cr.move_to(x, y)
      cr.line_to(x, y)
      cr.set_line_width(BRUSH_WIDTH)
      cr.set_line_cap(Cairo::LINE_CAP_ROUND)
      cr.set_source_rgb(0, 0, 0)
      cr.stroke
      cr.destroy
    end

    scribble_area.queue_draw
  end

  # -- Knockout groups ----------------------------------------------------
  # A black disc with three circles punched out of it, then the same three
  # circles painted back at half intensity and added on top.

  def draw_groups(cr, width, height)
    fill_checks(cr, width, height)

    (0.5 * [width, height].min - 10).then do |radius|
      [width / 2.0, height / 2.0].then do |xc, yc|
        cr.push_group

        cr.set_source_rgb(0, 0, 0)
        oval_path(cr, xc, yc, radius, radius)
        cr.fill

        cr.push_group
        draw_three_circles(cr, xc, yc, radius, 1.0)
        cr.pop_group.then do |punch|
          cr.operator = Cairo::OPERATOR_DEST_OUT
          cr.set_source(punch)
          cr.paint
        end

        cr.push_group
        cr.operator = Cairo::OPERATOR_OVER
        draw_three_circles(cr, xc, yc, radius, 0.5)
        cr.pop_group.then do |circles|
          cr.operator = Cairo::OPERATOR_ADD
          cr.set_source(circles)
          cr.paint
        end

        cr.pop_group.then do |overlay|
          cr.operator = Cairo::OPERATOR_OVER
          cr.set_source(overlay)
          cr.paint
        end
      end
    end
  end

  # The standard grey checkerboard used to show compositing effects.
  def fill_checks(cr, width, height)
    cr.rectangle(0, 0, width, height)
    cr.set_source_rgb(0.4, 0.4, 0.4)
    cr.fill

    (0...height).step(CHECK_SIZE) do |j|
      (0...width).step(CHECK_SIZE) do |i|
        cr.rectangle(i, j, CHECK_SIZE, CHECK_SIZE) if ((i / CHECK_SIZE) + (j / CHECK_SIZE)).even?
      end
    end

    cr.set_source_rgb(0.7, 0.7, 0.7)
    cr.fill
  end

  def oval_path(cr, xc, yc, xr, yr)
    cr.save
    cr.translate(xc, yc)
    cr.scale(1.0, yr / xr)
    cr.move_to(xr, 0.0)
    cr.arc(0, 0, xr, 0, 2 * Math::PI)
    cr.close_path
    cr.restore
  end

  def draw_three_circles(cr, xc, yc, radius, alpha)
    (radius * ((2 / 3.0) - 0.1)).then do |subradius|
      [[1, 0, 0, 0.5], [0, 1, 0, 0.5 + (2 / 0.3)], [0, 0, 1, 0.5 + (4 / 0.3)]].each do |red, green, blue, turns|
        cr.set_source_rgba(red, green, blue, alpha)
        oval_path(cr,
                  xc + (radius / 3.0 * Math.cos(Math::PI * turns)),
                  yc - (radius / 3.0 * Math.sin(Math::PI * turns)),
                  subradius, subradius)
        cr.fill
      end
    end
  end
end

DrawingAreaDemo.new.build.run
