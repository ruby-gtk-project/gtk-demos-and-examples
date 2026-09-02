require 'gtk4'

# Five rows of three buttons, each row chained together a different way.
# Widen the window to see the rows react differently.
#
# The rows are separated by "barrier" guides: zero-width spacers that every
# button in the rows above and below is pinned to.
class ConstraintsGrid < Gtk::Widget
  type_register

  REQUIRED = Gtk::ConstraintStrength::REQUIRED.to_i
  GAP = 10.0

  def initialize
    super()
    build
  end

  def build
    self.layout_manager = layout

    buttons.each { |button| button.parent = self }

    layout.tap do |manager|
      (spread_guides + inside_guides + packed_guides + bias_guides + barriers)
        .each { |guide| manager.add_guide(guide) }

      constraints.each { |constraint| manager.add_constraint(constraint) }
    end
  end

  def layout = @layout ||= Gtk::ConstraintLayout.new

  def buttons
    @buttons ||= Array.new(15) { |i| Gtk::Button.new(label: %w[A B C][i % 3]) }
  end

  # Four guides surrounding and separating the first row.
  def spread_guides = @spread_guides ||= Array.new(4) { stretchy_guide(10) }

  # Two guides between the buttons of the second row only.
  def inside_guides = @inside_guides ||= Array.new(2) { stretchy_guide(10) }

  # A guide at each end of the fourth row.
  def packed_guides = @packed_guides ||= Array.new(2) { stretchy_guide(10) }

  # A guide at each end of the fifth row, the left one four times as wide.
  def bias_guides = @bias_guides ||= Array.new(2) { stretchy_guide(0) }

  def barriers = @barriers ||= Array.new(4) { Gtk::ConstraintGuide.new.tap { |g| g.set_min_size(0, 10) } }

  private

  def stretchy_guide(min_width)
    Gtk::ConstraintGuide.new.tap do |guide|
      guide.set_min_size(min_width, 0)
      guide.set_nat_size(200, 0)
      guide.strength = :weak
    end
  end

  def row(index) = buttons[index * 3, 3]

  def constraints
    spread_chain + spread_inside_chain + weighted_chain + packed_chain + bias_chain
  end

  # Equal gaps at both ends and between the buttons.
  def spread_chain
    row(0).then do |a, b, c|
      spread_guides.then do |g1, g2, g3, g4|
        [
          relate(nil, :left, g1, :left), relate(a, :left, g1, :right),
          relate(g2, :left, a, :right), relate(b, :left, g2, :right),
          relate(g3, :left, b, :right), relate(c, :left, g3, :right),
          relate(g4, :left, c, :right), relate(nil, :right, g4, :right),
          equal_width(g1, g2), equal_width(g2, g3), equal_width(g3, g4),
          equal_width(a, b), equal_width(b, c)
        ] + [a, b, c].flat_map { |button| [relate(nil, :top, button, :top), relate(button, :bottom, barriers[0], :top)] }
      end
    end
  end

  # Flush with the edges, gaps only between the buttons.
  def spread_inside_chain
    row(1).then do |a, b, c|
      inside_guides.then do |g5, g6|
        [
          relate(nil, :left, a, :left),
          relate(g5, :left, a, :right), relate(b, :left, g5, :right),
          relate(g6, :left, b, :right), relate(c, :left, g6, :right),
          relate(nil, :right, c, :right),
          equal_width(g5, g6), equal_width(a, b), equal_width(b, c)
        ] + stack([a, b, c], barriers[0], barriers[1])
      end
    end
  end

  # Fixed gaps, with the buttons in a 1 : 2 : 3 width ratio.
  def weighted_chain
    row(2).then do |a, b, c|
      [
        relate(nil, :left, a, :left),
        relate(b, :left, a, :right, GAP),
        relate(c, :left, b, :right, GAP),
        relate(nil, :right, c, :right),
        relate(b, :width, a, :width, 0.0, 2.0),
        relate(c, :width, a, :width, 0.0, 3.0)
      ] + stack([a, b, c], barriers[1], barriers[2])
    end
  end

  # Equal buttons with fixed gaps, centred by two equal guides.
  def packed_chain
    row(3).then do |a, b, c|
      packed_guides.then do |g7, g8|
        [
          relate(nil, :left, g7, :left), relate(a, :left, g7, :right),
          relate(b, :left, a, :right, GAP), relate(c, :left, b, :right, GAP),
          relate(g8, :left, c, :right), relate(nil, :right, g8, :right),
          equal_width(g7, g8), equal_width(a, b), equal_width(b, c)
        ] + stack([a, b, c], barriers[2], barriers[3])
      end
    end
  end

  # As above, but the left guide is four times the right one, so the row is
  # pushed towards the right-hand edge.
  def bias_chain
    row(4).then do |a, b, c|
      bias_guides.then do |g9, g10|
        [
          relate(nil, :left, g9, :left), relate(a, :left, g9, :right, GAP),
          relate(b, :left, a, :right, GAP), relate(c, :left, b, :right, GAP),
          relate(g10, :left, c, :right, GAP), relate(nil, :right, g10, :right),
          relate(g9, :width, g10, :width, 0.0, 4.0),
          equal_width(a, b), equal_width(b, c)
        ] +
          [a, b, c].map { |button| relate(button, :top, barriers[3], :bottom) } +
          [a, b, c].map { |button| Gtk::Constraint.new(nil, :bottom, :ge, button, :bottom, 1.0, 0.0, REQUIRED) }
      end
    end
  end

  def stack(row_buttons, above, below)
    row_buttons.flat_map do |button|
      [relate(button, :top, above, :bottom), relate(button, :bottom, below, :top)]
    end
  end

  def equal_width(target, source) = relate(target, :width, source, :width)

  def relate(target, target_attribute, source, source_attribute, constant = 0.0, multiplier = 1.0)
    Gtk::Constraint.new(target, target_attribute, :eq, source, source_attribute,
                        multiplier, constant, REQUIRED)
  end
end

class ConstraintsBuilderDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Constraints — Builder'
          win.set_default_size(260, -1)
          win.child = grid
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.constraints_builder', :default_flags)
  def window = @window ||= Gtk::Window.new

  def grid
    @grid ||= ConstraintsGrid.new.tap do |g|
      g.halign = :fill
      g.valign = :fill
      g.margin_top = 10
      g.margin_bottom = 10
      g.margin_start = 10
      g.margin_end = 10
    end
  end
end

ConstraintsBuilderDemo.new.build.run
