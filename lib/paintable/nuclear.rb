require 'gtk4'

# The radiation-warning icon the paintable demos all draw: a filled centre
# disc inside a thick dashed circle, rotated by a given number of degrees.
module Nuclear
  RADIUS = 0.3
  CENTRE_RADIUS = 0.1
  BLACK = Gdk::RGBA.new(0, 0, 0, 1).freeze
  YELLOW = Gdk::RGBA.new(0.9, 0.75, 0.15, 1.0).freeze

  module_function

  def snapshot(snapshot, foreground, background, width, height, rotation)
    snapshot.append_color(background, Graphene::Rect.new(0, 0, width, height))

    snapshot.save
    snapshot.translate(Graphene::Point.new(width / 2.0, height / 2.0))
    [width, height].min.then { |size| snapshot.scale(size, size) }
    snapshot.rotate(rotation)

    snapshot.append_fill(circle(CENTRE_RADIUS), :winding, foreground)
    snapshot.append_stroke(circle(RADIUS), dashed_stroke, foreground)

    snapshot.restore
  end

  def circle(radius)
    Gsk::PathBuilder.new.tap { |builder| builder.add_circle(Graphene::Point.new(0, 0), radius) }.to_path
  end

  # Three dashes with three equal gaps make the classic trefoil.
  def dashed_stroke
    Gsk::Stroke.new(RADIUS).tap { |stroke| stroke.dash = [RADIUS * Math::PI / 3] }
  end
end

# A still nuclear icon. Implementing GdkPaintable means implementing exactly
# one method: the snapshot that does the drawing.
class NuclearIcon < GLib::Object
  type_register
  include Gdk::Paintable

  def initialize(rotation = 0.0)
    super()
    @rotation = rotation
  end

  def virtual_do_snapshot(snapshot, width, height)
    Nuclear.snapshot(snapshot, Nuclear::BLACK, Nuclear::YELLOW, width, height, @rotation)
  end
end

# The same icon, rotating. A paintable that changes has to tell GTK when its
# contents went stale, and has to be able to hand out a still image of the
# moment for anything that needs one.
class NuclearAnimation < GLib::Object
  type_register
  include Gdk::Paintable

  # A full turn takes 500 steps of 10ms, so five seconds.
  MAX_PROGRESS = 500
  STEP_INTERVAL = 10
  TRANSPARENT = Gdk::RGBA.new(0, 0, 0, 0).freeze

  def initialize(draw_background)
    super()
    @draw_background = draw_background
    @progress = 0
    start
  end

  def virtual_do_snapshot(snapshot, width, height)
    Nuclear.snapshot(snapshot, Nuclear::BLACK, background, width, height, rotation)
  end

  def virtual_do_get_current_image = NuclearIcon.new(rotation)

  private

  def background = @draw_background ? Nuclear::YELLOW : TRANSPARENT

  def rotation = 360.0 * @progress / MAX_PROGRESS

  def start
    GLib::Timeout.add(STEP_INTERVAL) do
      @progress = (@progress + 1) % MAX_PROGRESS
      invalidate_contents
      GLib::Source::CONTINUE
    end
  end
end
