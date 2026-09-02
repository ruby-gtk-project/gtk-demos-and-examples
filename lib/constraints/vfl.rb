require 'gtk4'

# The same three-button layout as the simple constraints demo, specified in
# the compact Visual Format Language:
#
#   H:|-8-[button1(==button2)]-12-[button2]-8-|
#   H:|-8-[button3]-8-|
#   V:|-8-[button1]-12-[button3(==button1)]-8-|
#   V:|-8-[button2]-12-[button3(==button2)]-8-|
#
# Gtk::ConstraintLayout#add_constraints_from_description takes a hash of
# widgets, which the Ruby bindings cannot marshal, so the VFL above is
# spelled out as the constraints it stands for.
class VflGrid < Gtk::Widget
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

    buttons.each_with_index do |button, index|
      button.parent = self
      button.name = "button#{index + 1}"
    end

    layout.tap { |manager| constraints.each { |constraint| manager.add_constraint(constraint) } }
  end

  def layout = @layout ||= Gtk::ConstraintLayout.new
  def buttons = @buttons ||= (1..3).map { |i| Gtk::Button.new(label: "Child #{i}") }
  def first_button = buttons[0]
  def second_button = buttons[1]
  def third_button = buttons[2]

  private

  def constraints
    [
      relate(nil, :start, first_button, :start, -MARGIN),
      relate(first_button, :width, second_button, :width, 0.0),
      relate(first_button, :end, second_button, :start, -GAP),
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

class VflConstraintsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Constraints — VFL'
          win.set_default_size(260, -1)
          win.child = content_box
        end

        content_box.tap { |box| box.append(grid) }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.constraints_vfl', :default_flags)
  def window = @window ||= Gtk::Window.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 12)

  def grid
    @grid ||= VflGrid.new.tap do |g|
      g.hexpand = true
      g.vexpand = true
    end
  end
end

VflConstraintsDemo.new.build.run
