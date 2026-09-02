require 'gtk4'

# Three buttons split by a zero-width guide. Dragging inside the widget moves
# that guide, which re-lays out everything attached to it: constraints can be
# added and removed while the app runs.
class InteractiveGrid < Gtk::Widget
  type_register

  REQUIRED = Gtk::ConstraintStrength::REQUIRED.to_i
  MARGIN = 8.0

  def initialize
    super()
    build
  end

  def build
    self.layout_manager = layout

    buttons.each_with_index do |button, index|
      button.parent = self
      button.name = "button#{index + 1}"
    end

    layout.tap do |manager|
      manager.add_guide(divider)
      constraints.each { |constraint| manager.add_constraint(constraint) }
    end

    add_controller(drag_gesture)

    drag_gesture.tap do |drag|
      drag.signal_connect('drag-update') { |_, offset_x, _| move_divider(offset_x) }
    end
  end

  def layout = @layout ||= Gtk::ConstraintLayout.new
  def drag_gesture = @drag_gesture ||= Gtk::GestureDrag.new
  def buttons = @buttons ||= (1..3).map { |i| Gtk::Button.new(label: "Child #{i}") }
  def first_button = buttons[0]
  def second_button = buttons[1]
  def third_button = buttons[2]
  def divider = @divider ||= Gtk::ConstraintGuide.new

  private

  def constraints
    [
      Gtk::Constraint.new(divider, :width, :eq, 0.0, REQUIRED),
      relate(nil, :start, first_button, :start, -MARGIN),
      relate(first_button, :end, divider, :start),
      relate(second_button, :start, divider, :end),
      relate(second_button, :end, nil, :end, -MARGIN),
      relate(nil, :start, third_button, :start, -MARGIN),
      relate(third_button, :end, divider, :start),
      relate(nil, :top, first_button, :top, -MARGIN),
      relate(second_button, :top, first_button, :bottom),
      relate(third_button, :top, second_button, :bottom),
      relate(third_button, :bottom, nil, :bottom, -MARGIN)
    ]
  end

  def relate(target, target_attribute, source, source_attribute, constant = 0.0)
    Gtk::Constraint.new(target, target_attribute, :eq, source, source_attribute, 1.0, constant, REQUIRED)
  end

  # The guide's position is itself a constraint, so moving it means swapping
  # one constant constraint for another.
  def move_divider(offset_x)
    layout.remove_constraint(@position) if @position

    drag_gesture.start_point.then do |_, x, _|
      @position = Gtk::Constraint.new(divider, :left, :eq, x + offset_x, REQUIRED)
      layout.add_constraint(@position)
    end

    queue_allocate
  end
end

class InteractiveConstraintsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Interactive Constraints'
          win.set_default_size(260, -1)
          win.child = content_box
        end

        content_box.tap { |box| box.append(grid) }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.constraints_interactive', :default_flags)
  def window = @window ||= Gtk::Window.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 12)

  def grid
    @grid ||= InteractiveGrid.new.tap do |g|
      g.hexpand = true
      g.vexpand = true
    end
  end
end

InteractiveConstraintsDemo.new.build.run
