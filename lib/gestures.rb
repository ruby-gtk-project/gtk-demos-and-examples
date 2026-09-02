require 'gtk4'

class GesturesDemo
  TOUCHPAD_FINGERS = 3

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Gestures'
          win.set_default_size(400, 400)
          win.child = drawing_area
        end

        drawing_area.tap do |area|
          area.set_draw_func { |_, cr, w, h| draw(cr, w, h) }

          gestures.each { |gesture| area.add_controller(gesture) }

          swipe_gesture.tap { |g| g.signal_connect('swipe') { |_, vx, vy| record_swipe(vx, vy) } }

          touchpad_swipe_gesture.tap do |g|
            g.signal_connect('swipe') { |_, vx, vy| record_swipe(vx, vy) }
            # Touchscreen sequences are handled by the single-finger gesture.
            g.signal_connect('begin') do |_, sequence|
              g.set_state(:denied) if sequence
              sequence.nil?
            end
          end

          long_press_gesture.tap do |g|
            g.signal_connect('pressed') { set_long_pressed(true) }
            g.signal_connect('end') { set_long_pressed(false) }
          end

          rotate_gesture.tap { |g| g.signal_connect('angle-changed') { area.queue_draw } }
          zoom_gesture.tap { |g| g.signal_connect('scale-changed') { area.queue_draw } }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.gestures', :default_flags)
  def window = @window ||= Gtk::Window.new
  def drawing_area = @drawing_area ||= Gtk::DrawingArea.new
  def swipe_gesture = @swipe_gesture ||= bubbling(Gtk::GestureSwipe.new)
  def long_press_gesture = @long_press_gesture ||= bubbling(Gtk::GestureLongPress.new)
  def rotate_gesture = @rotate_gesture ||= bubbling(Gtk::GestureRotate.new)
  def zoom_gesture = @zoom_gesture ||= bubbling(Gtk::GestureZoom.new)
  def swipe_x = @swipe_x ||= 0
  def swipe_y = @swipe_y ||= 0

  # "n-points" is construct-only, and Gtk::GestureSwipe.new does not accept
  # it, so the gesture has to be built with GLib::Object.new!.
  def touchpad_swipe_gesture
    @touchpad_swipe_gesture ||= bubbling(Gtk::GestureSwipe.new!('n-points' => TOUCHPAD_FINGERS))
  end

  def gestures
    @gestures ||= [swipe_gesture, touchpad_swipe_gesture, long_press_gesture, rotate_gesture, zoom_gesture]
  end

  private

  def bubbling(gesture) = gesture.tap { |g| g.propagation_phase = :bubble }

  def record_swipe(velocity_x, velocity_y)
    @swipe_x = velocity_x / 10
    @swipe_y = velocity_y / 10
    drawing_area.queue_draw
  end

  def set_long_pressed(pressed)
    @long_pressed = pressed
    drawing_area.queue_draw
  end

  def draw(cr, width, height)
    draw_swipe(cr, width, height)
    draw_transformed_square(cr)
    draw_long_press(cr, width, height)
  end

  # A red line showing the direction and speed of the last swipe.
  def draw_swipe(cr, width, height)
    if !swipe_x.zero? || !swipe_y.zero?
      cr.save
      cr.set_line_width(6)
      cr.move_to(width / 2, height / 2)
      cr.rel_line_to(swipe_x, swipe_y)
      cr.set_source_rgba(1, 0, 0, 0.5)
      cr.stroke
      cr.restore
    end
  end

  # A gradient square that follows the current rotate and zoom gestures.
  def draw_transformed_square(cr)
    if rotate_gesture.recognized? || zoom_gesture.recognized?
      cr.save

      zoom_gesture.bounding_box_center.then do |_, x_center, y_center|
        cr.matrix.dup.tap do |matrix|
          matrix.translate(x_center, y_center)
          matrix.rotate(rotate_gesture.angle_delta)
          zoom_gesture.scale_delta.then { |scale| matrix.scale(scale, scale) }
          cr.set_matrix(matrix)
        end
      end

      cr.rectangle(-100, -100, 200, 200)

      Cairo::LinearPattern.new(-100, 0, 200, 0).tap do |pattern|
        pattern.add_color_stop_rgb(0, 0, 0, 1)
        pattern.add_color_stop_rgb(1, 1, 0, 0)
        cr.set_source(pattern)
        cr.fill
      end

      cr.restore
    end
  end

  # A green ring while a long press is held.
  def draw_long_press(cr, width, height)
    if @long_pressed
      cr.save
      cr.arc(width / 2, height / 2, 50, 0, 2 * Math::PI)
      cr.set_source_rgba(0, 1, 0, 0.5)
      cr.stroke
      cr.restore
    end
  end
end

GesturesDemo.new.build.run
