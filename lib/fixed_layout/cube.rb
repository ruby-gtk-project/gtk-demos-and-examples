require 'gtk4'

# Six frames arranged into a cube by giving each one a 3D transform. The
# order of the list is the paint order, back to front.
class FixedCubeDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze
  FACE_SIZE = 200
  PRIORITY = 800

  # css class, rotation in degrees, axis to rotate about
  FACES = [
    ['back', -180.0, :y],
    ['left', -90.0, :y],
    ['bottom', -90.0, :x],
    ['right', 90.0, :y],
    ['top', 90.0, :x],
    ['front', 0.0, :y]
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Fixed Layout ‐ Cube'
          win.set_default_size(600, 400)
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = outer_fixed }

        outer_fixed.tap { |f| f.put(cube, 0, 0) }

        cube.tap do |c|
          faces.each_with_index do |face, index|
            c.put(face, 0, 0)
            c.set_child_transform(face, face_transform(*FACES[index][1..]))
          end
        end

        Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, PRIORITY)

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.fixed_cube', :default_flags)
  def window = @window ||= Gtk::Window.new
  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def cube = @cube ||= Gtk::Fixed.new.tap { |f| f.overflow = :visible }
  def provider = @provider ||= Gtk::CssProvider.new.tap { |p| p.load(path: File.join(ASSETS, 'fixed.css')) }

  def outer_fixed
    @outer_fixed ||= Gtk::Fixed.new.tap do |f|
      f.overflow = :visible
      f.halign = :center
      f.valign = :center
    end
  end

  def faces
    @faces ||= FACES.map do |css_class, _, _|
      Gtk::Frame.new.tap do |frame|
        frame.set_size_request(FACE_SIZE, FACE_SIZE)
        frame.add_css_class(css_class)
      end
    end
  end

  private

  def half = FACE_SIZE / 2.0

  # Every face starts from the same view of the cube, is turned to its own
  # side, then pushed out to the surface.
  def face_transform(angle, axis)
    Gsk::Transform.new
                  .translate(Graphene::Point.new(half, half))
                  .perspective(FACE_SIZE * 3.0)
                  .rotate_3d(-30.0, x_axis)
                  .rotate_3d(135.0, y_axis)
                  .translate_3d(point3d(0, 0, -FACE_SIZE / 6.0))
                  .rotate_3d(angle, axis == :x ? x_axis : y_axis)
                  .translate_3d(point3d(0, 0, half))
                  .translate_3d(point3d(-half, -half, 0))
  end

  # Graphene::Point3D takes no constructor arguments in the Ruby bindings.
  def point3d(x, y, z) = Graphene::Point3D.new.tap { |point| point.init(x, y, z) }

  def x_axis = @x_axis ||= Graphene::Vec3.x_axis
  def y_axis = @y_axis ||= Graphene::Vec3.y_axis
end

FixedCubeDemo.new.build.run
