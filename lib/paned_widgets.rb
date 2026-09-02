require 'gtk4'

class PanedWidgetsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Paned Widgets'
          win.set_default_size(330, 250)
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(frame)

          frame.tap do |f|
            f.child = vertical_pane

            vertical_pane.tap do |vp|
              vp.start_child = horizontal_pane
              vp.shrink_start_child = false
              vp.end_child = goodbye_label
              vp.shrink_end_child = false

              horizontal_pane.tap do |hp|
                hp.start_child = hi_label
                hp.shrink_start_child = false
                hp.end_child = hello_label
                hp.shrink_end_child = false
              end
            end
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paned_widgets', :default_flags)
  def window = @window ||= Gtk::Window.new
  def frame = @frame ||= Gtk::Frame.new
  def vertical_pane = @vertical_pane ||= Gtk::Paned.new(:vertical)
  def horizontal_pane = @horizontal_pane ||= Gtk::Paned.new(:horizontal)
  def hi_label = @hi_label ||= pane_label('Hi there')
  def hello_label = @hello_label ||= pane_label('Hello')
  def goodbye_label = @goodbye_label ||= pane_label('Goodbye')

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  private

  def pane_label(text)
    Gtk::Label.new(text).tap do |l|
      l.margin_start = 4
      l.margin_end = 4
      l.margin_top = 4
      l.margin_bottom = 4
      l.hexpand = true
      l.vexpand = true
    end
  end
end

PanedWidgetsDemo.new.build.run
