require 'gtk4'

class StyleClassesDemo
  LINKED_LABELS = ['Hi, I am a button', "And I'm another button", 'This is a button party!'].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Style Classes'
          win.resizable = false
          win.child = grid
        end

        grid.tap do |g|
          g.attach(linked_box, 0, 0, 1, 1)
          g.attach(actions_box, 0, 1, 1, 1)

          linked_box.tap do |box|
            linked_buttons.each { |button| box.append(button) }
          end

          actions_box.tap do |box|
            box.append(plain_button)
            box.append(destructive_button)
            box.append(suggested_button)
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.style_classes', :default_flags)
  def window = @window ||= Gtk::Window.new
  def actions_box = @actions_box ||= Gtk::Box.new(:horizontal, 10)
  def destructive_button = @destructive_button ||= action_button('Destructive', 'destructive-action')
  def suggested_button = @suggested_button ||= action_button('Suggested', 'suggested-action')

  def linked_buttons
    @linked_buttons ||= LINKED_LABELS.map do |label|
      Gtk::Button.new(label: label).tap { |btn| btn.receives_default = true }
    end
  end

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.orientation = :vertical
      g.row_spacing = 10
      g.margin_start = 10
      g.margin_end = 10
      g.margin_top = 10
      g.margin_bottom = 10
    end
  end

  def linked_box
    @linked_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.add_css_class('linked')
      box.halign = :center
      box.valign = :center
    end
  end

  def plain_button
    @plain_button ||= Gtk::Button.new(label: 'Plain').tap do |btn|
      btn.halign = :end
      btn.hexpand = true
      btn.vexpand = true
    end
  end

  private

  def action_button(label, css_class)
    Gtk::Button.new(label: label).tap { |btn| btn.add_css_class(css_class) }
  end
end

StyleClassesDemo.new.build.run
