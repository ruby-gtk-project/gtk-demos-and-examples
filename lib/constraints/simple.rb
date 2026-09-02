require 'gtk4'

# Three buttons laid out by relations rather than by boxes or grids:
#
#   +-------------------------------------+
#   | +-----------++-------++-----------+ |
#   | |  Child 1  || Space ||  Child 2  | |
#   | +-----------++-------++-----------+ |
#   | +---------------------------------+ |
#   | |             Child 3             | |
#   | +---------------------------------+ |
#   +-------------------------------------+
#
# "Space" is a guide: a spacer that takes part in the constraints but draws
# nothing, and here it is allowed to stretch between 10 and 200 pixels.
class SimpleGrid < Gtk::Widget
  type_register

  REQUIRED = Gtk::ConstraintStrength::REQUIRED.to_i
  MARGIN = 8.0
  GAP = 12.0

  def initialize
    super()
    build
  end

  def build
    self.layout_manager = layout

    buttons.each { |button| button.parent = self }

    layout.tap do |manager|
      manager.add_guide(space)
      constraints.each { |constraint| manager.add_constraint(constraint) }
    end
  end

  def layout = @layout ||= Gtk::ConstraintLayout.new
  def buttons = @buttons ||= (1..3).map { |i| Gtk::Button.new(label: "Child #{i}") }
  def first_button = buttons[0]
  def second_button = buttons[1]
  def third_button = buttons[2]

  def space
    @space ||= Gtk::ConstraintGuide.new.tap do |guide|
      guide.name = 'space'
      guide.set_min_size(10, 10)
      guide.set_nat_size(100, 10)
      guide.set_max_size(200, 20)
      guide.strength = :strong
    end
  end

  private

  def constraints
    [
      Gtk::Constraint.new(first_button, :width, :le, 200.0, REQUIRED),
      relate(nil, :start, first_button, :start, -MARGIN),
      relate(first_button, :width, second_button, :width, 0.0),
      relate(first_button, :end, space, :start, 0.0),
      relate(space, :end, second_button, :start, 0.0),
      relate(second_button, :end, nil, :end, -MARGIN),
      relate(nil, :start, third_button, :start, -MARGIN),
      relate(third_button, :end, nil, :end, -MARGIN),
      relate(nil, :top, first_button, :top, -MARGIN),
      relate(nil, :top, second_button, :top, -MARGIN),
      relate(first_button, :bottom, third_button, :top, -GAP),
      relate(second_button, :bottom, third_button, :top, -GAP),
      relate(third_button, :height, first_button, :height, 0.0),
      relate(third_button, :height, second_button, :height, 0.0),
      relate(third_button, :bottom, nil, :bottom, -MARGIN)
    ]
  end

  def relate(target, target_attribute, source, source_attribute, constant)
    Gtk::Constraint.new(target, target_attribute, :eq, source, source_attribute, 1.0, constant, REQUIRED)
  end
end

class SimpleConstraintsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Simple Constraints'
          win.set_default_size(260, -1)
          win.child = content_box
        end

        content_box.tap { |box| box.append(grid) }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.constraints', :default_flags)
  def window = @window ||= Gtk::Window.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 12)

  def grid
    @grid ||= SimpleGrid.new.tap do |g|
      g.hexpand = true
      g.vexpand = true
    end
  end
end

SimpleConstraintsDemo.new.build.run
