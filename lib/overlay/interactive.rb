require 'gtk4'

class InteractiveOverlayDemo
  SIDE = 5

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Interactive Overlay'
          win.set_default_size(500, 510)
          win.child = overlay
        end

        overlay.tap do |o|
          o.child = grid
          o.add_overlay(title_box)
          o.add_overlay(entry_box)

          grid.tap do |g|
            buttons.each_with_index do |button, index|
              g.attach(button, index % SIDE, index / SIDE, 1, 1)
              button.signal_connect('clicked') { entry.text = button.label }
            end
          end

          title_box.tap { |box| box.append(title_label) }
          entry_box.tap { |box| box.append(entry) }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.overlay', :default_flags)
  def window = @window ||= Gtk::Window.new
  def overlay = @overlay ||= Gtk::Overlay.new
  def grid = @grid ||= Gtk::Grid.new

  def buttons
    @buttons ||= (0...(SIDE * SIDE)).map do |number|
      Gtk::Button.new(label: number.to_s).tap do |btn|
        btn.hexpand = true
        btn.vexpand = true
      end
    end
  end

  # Purely decorative, so it must not swallow clicks meant for the grid.
  def title_box
    @title_box ||= Gtk::Box.new(:vertical, 10).tap do |box|
      box.can_target = false
      box.halign = :center
      box.valign = :start
    end
  end

  def title_label
    @title_label ||= Gtk::Label.new("<span foreground='blue' weight='ultrabold' font='40'>Numbers</span>").tap do |label|
      label.use_markup = true
      label.can_target = false
      label.margin_top = 8
      label.margin_bottom = 8
    end
  end

  def entry_box
    @entry_box ||= Gtk::Box.new(:vertical, 10).tap do |box|
      box.halign = :center
      box.valign = :center
    end
  end

  def entry
    @entry ||= Gtk::Entry.new.tap do |e|
      e.placeholder_text = 'Your Lucky Number'
      e.margin_top = 8
      e.margin_bottom = 8
    end
  end
end

InteractiveOverlayDemo.new.build.run
