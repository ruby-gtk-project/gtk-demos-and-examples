require 'gtk4'

class ScalesDemo
  MARKS = [0, 1, 2, 3, 4].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Scales'
          win.resizable = false
          win.child = grid
        end

        grid.tap do |g|
          g.attach(plain_label, 0, 0, 1, 1)
          g.attach(plain_scale, 1, 0, 1, 1)
          g.attach(marks_label, 0, 1, 1, 1)
          g.attach(marks_scale, 1, 1, 1, 1)
          g.attach(discrete_label, 0, 2, 1, 1)
          g.attach(discrete_scale, 1, 2, 1, 1)
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.scales', :default_flags)
  def window = @window ||= Gtk::Window.new
  def plain_label = @plain_label ||= row_label('Plain')
  def marks_label = @marks_label ||= row_label('Marks')
  def discrete_label = @discrete_label ||= row_label('Discrete')
  def plain_scale = @plain_scale ||= scale
  def marks_scale = @marks_scale ||= scale.tap { |s| add_marks(s) }

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.row_spacing = 10
      g.column_spacing = 10
      g.margin_start = 20
      g.margin_end = 20
      g.margin_top = 20
      g.margin_bottom = 20
    end
  end

  def discrete_scale
    @discrete_scale ||= scale.tap do |s|
      s.round_digits = 0
      add_marks(s)
    end
  end

  private

  def row_label(text) = Gtk::Label.new(text).tap { |l| l.xalign = 0 }

  def adjustment = Gtk::Adjustment.new(2, 0, 4, 0.1, 1, 0)

  def scale
    Gtk::Scale.new(:horizontal, adjustment).tap do |s|
      s.width_request = 200
      s.draw_value = false
      s.hexpand = true
    end
  end

  def add_marks(scale)
    MARKS.each { |value| scale.add_mark(value, :bottom, nil) }
  end
end

ScalesDemo.new.build.run
