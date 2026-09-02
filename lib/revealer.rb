require 'gtk4'

class RevealerDemo
  # column, row, transition type — a cross of faces radiating from the centre
  REVEALERS = [
    [2, 2, :crossfade],
    [2, 1, :slide_up],
    [3, 2, :slide_right],
    [2, 3, :none],
    [1, 2, :slide_left],
    [2, 0, :slide_up],
    [4, 2, :slide_right],
    [2, 4, :none],
    [0, 2, :slide_left]
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Revealer'
          win.set_default_size(300, 300)
          win.child = grid
        end

        grid.tap do |g|
          REVEALERS.each_with_index do |(column, row, _), i|
            g.attach(revealers[i], column, row, 1, 1)
          end
        end

        reveal_next

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.revealer', :default_flags)
  def window = @window ||= Gtk::Window.new
  def revealed_count = @revealed_count ||= 0

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.halign = :center
      g.valign = :center
    end
  end

  def revealers
    @revealers ||= REVEALERS.map do |_, _, transition|
      Gtk::Revealer.new.tap do |revealer|
        revealer.transition_duration = 2000
        revealer.transition_type = transition
        revealer.child = face_image
      end
    end
  end

  private

  def face_image
    Gtk::Image.new.tap do |image|
      image.icon_name = 'face-cool-symbolic'
      image.icon_size = :large
    end
  end

  # Reveals one more face every 690ms, then leaves each one pulsing forever.
  def reveal_next
    GLib::Timeout.add(690) do
      revealers[revealed_count].tap do |revealer|
        revealer.reveal_child = true
        revealer.signal_connect('notify::child-revealed') { change_direction(revealer) }
      end

      @revealed_count = revealed_count + 1
      revealed_count < REVEALERS.size
    end
  end

  def change_direction(revealer)
    revealer.reveal_child = !revealer.child_revealed? if revealer.mapped?
  end
end

RevealerDemo.new.build.run
