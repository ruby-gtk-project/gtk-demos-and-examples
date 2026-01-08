require 'gtk4'

class StackSidebarDemo
  PAGES = [
    'Welcome to GTK',
    'GtkStackSidebar Widget',
    'Automatic navigation',
    'Consistent appearance',
    'Scrolling',
    'Page 6',
    'Page 7',
    'Page 8',
    'Page 9'
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        window.titlebar = header_bar
        window.title = 'Stack Sidebar'
        window.resizable = true

        main_box.tap do |box|
          window.child = box

          box.append(sidebar)
          box.append(stack)

          stack.tap do
            sidebar.stack = stack
            stack.transition_type = :slide_up_down
            stack.hexpand = true

            PAGES.each_with_index do |title, i| 

              if i == 0 then welcome_image else Gtk::Label.new(title) end.then do |content|
                stack.add_named(content, PAGES[i]).tap do |page|
                  page.title = title
                end
              end

            end
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.stack_sidebar', :default_flags)
  def window = @window ||= Gtk::ApplicationWindow.new(app)
  def header_bar = @header_bar ||= Gtk::HeaderBar.new
  def main_box = @main_box ||= Gtk::Box.new(:horizontal, 0)
  def sidebar = @sidebar ||= Gtk::StackSidebar.new
  def stack = @stack ||= Gtk::Stack.new

  def welcome_image
    @welcome_image ||= Gtk::Image.new.tap do |img|
      img.icon_name = 'org.gtk.Demo4'
      img.add_css_class('icon-dropshadow')
      img.pixel_size = 256
    end
  end

end

StackSidebarDemo.new.build.run
