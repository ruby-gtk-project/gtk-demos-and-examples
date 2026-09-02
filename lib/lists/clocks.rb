require 'gtk4'

# A clock face for one timezone. Implementing GdkPaintable means the object
# itself can be handed to a Gtk::Picture, so the list items display the model
# objects directly rather than some widget built from them.
class Clock < GLib::Object
  type_register
  include Gdk::Paintable

  SIZE = 100
  BLACK = Gdk::RGBA.new(0, 0, 0, 1).freeze

  attr_reader :location

  def initialize(location, timezone = nil)
    super()
    @location = location
    @timezone = GLib::TimeZone.new(timezone || 'local')
    @observers = []
  end

  def time = GLib::DateTime.now(@timezone)

  def formatted_time = time.format("%x\n%X")

  # Everything that wants to know when this clock moved on.
  def observe(&block) = @observers << block
  def forget(block) = @observers.delete(block)

  def tick
    invalidate_contents
    @observers.each(&:call)
  end

  def virtual_do_get_intrinsic_width = SIZE
  def virtual_do_get_intrinsic_height = SIZE

  # Drawn entirely with transforms: each hand is the same upright rounded
  # rectangle, rotated into place.
  def virtual_do_snapshot(snapshot, width, height)
    snapshot.save
    snapshot.translate(Graphene::Point.new(width / 2, height / 2))
    ([width, height].min / SIZE.to_f).then { |scale| snapshot.scale(scale, scale) }

    time.then do |now|
      draw_face(snapshot)
      draw_hand(snapshot, (30 * (now.hour % 12)) + (0.5 * now.minute), -23, 25)
      draw_hand(snapshot, 6 * now.minute, -43, 45)
      draw_hand(snapshot, 6 * now.second, -43, 10)
    end

    snapshot.restore
  end

  private

  # A rounded rectangle with a radius of half its size is a circle.
  def draw_face(snapshot)
    snapshot.append_border(rounded_rect(-50, -50, 100, 100, 50),
                           [4, 4, 4, 4], [BLACK, BLACK, BLACK, BLACK])
  end

  def draw_hand(snapshot, degrees, top, length)
    snapshot.save
    snapshot.rotate(degrees)

    rounded_rect(-2, top, 4, length, 2).tap do |outline|
      snapshot.push_rounded_clip(outline)
      snapshot.append_color(BLACK, outline.bounds)
      snapshot.pop
    end

    snapshot.restore
  end

  def rounded_rect(x, y, width, height, radius)
    Gsk::RoundedRect.new.init_from_rect(Graphene::Rect.new(x, y, width, height), radius)
  end
end

class ClocksDemo
  ZONES = [
    ['local', nil],
    ['UTC', 'UTC'],
    ['San Francisco', 'America/Los_Angeles'],
    ['Xalapa', 'America/Mexico_City'],
    ['Boston', 'America/New_York'],
    ['London', 'Europe/London'],
    ['Berlin', 'Europe/Berlin'],
    ['Moscow', 'Europe/Moscow'],
    ['New Delhi', 'Asia/Kolkata'],
    ['Shanghai', 'Asia/Shanghai']
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Clocks'
          win.set_default_size(600, 400)
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = grid_view }

        start_ticking

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.listview_clocks', :default_flags)
  def window = @window ||= Gtk::Window.new
  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def clocks = @clocks ||= ZONES.map { |location, zone| Clock.new(location, zone) }

  def model
    @model ||= Gio::ListStore.new(Clock.gtype).tap do |store|
      clocks.each { |clock| store.append(clock) }
    end
  end

  def grid_view
    @grid_view ||= Gtk::GridView.new(Gtk::NoSelection.new(model), factory).tap do |view|
      view.hscroll_policy = :natural
      view.vscroll_policy = :natural
    end
  end

  # Each cell is a location, the clock face itself, and the time as text.
  def factory
    @factory ||= Gtk::SignalListItemFactory.new.tap do |f|
      f.signal_connect('setup') do |_, item|
        item.child = Gtk::Box.new(:vertical, 0).tap do |box|
          box.append(Gtk::Label.new)
          box.append(Gtk::Picture.new)
          box.append(Gtk::Label.new)
        end
      end

      f.signal_connect('bind') { |_, item| bind_item(item) }
      f.signal_connect('unbind') { |_, item| unbind_item(item) }
    end
  end

  def observers = @observers ||= {}

  private

  def bind_item(item)
    item.item.then do |clock|
      item.child.first_child.then do |location_label|
        location_label.label = clock.location
        location_label.next_sibling.tap { |picture| picture.paintable = clock }
        location_label.next_sibling.next_sibling.tap do |time_label|
          time_label.label = clock.formatted_time
          observers[item] = -> { time_label.label = clock.formatted_time }
          clock.observe(&observers[item])
        end
      end
    end
  end

  def unbind_item(item)
    observers.delete(item).then { |observer| item.item.forget(observer) if observer }
  end

  def start_ticking
    GLib::Timeout.add_seconds(1) do
      clocks.each(&:tick)
      GLib::Source::CONTINUE
    end
  end
end

ClocksDemo.new.build.run
