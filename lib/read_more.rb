require 'gtk4'

# A widget that shows its whole text when there is room for it, and otherwise
# shows the first few lines with a "Read More" button underneath. Once the
# button is pressed the full text stays visible for good.
class ReadMore < Gtk::Widget
  type_register

  def initialize(text)
    super()
    @text = text
    @show_more = false
    build
  end

  def build
    label.parent = self
    box.parent = self

    box.tap do |b|
      b.append(inscription)
      b.append(button)

      button.tap do |btn|
        btn.signal_connect('clicked') do
          @show_more = true
          queue_resize
        end
      end
    end
  end

  def virtual_do_get_request_mode = Gtk::SizeRequestMode::HEIGHT_FOR_WIDTH

  # Report whichever of the two children actually fits; once "Read More" has
  # been pressed only the full label counts.
  def virtual_do_measure(orientation, for_size)
    if @show_more || !fits?(box, orientation, for_size)
      label.measure(orientation, for_size)
    elsif !fits?(label, orientation, for_size)
      box.measure(orientation, for_size)
    else
      smaller_of(label.measure(orientation, for_size), box.measure(orientation, for_size))
    end
  end

  def virtual_do_size_allocate(width, height, baseline)
    showing_all_text?(width, height).then do |show_all|
      label.set_child_visible(show_all)
      box.set_child_visible(!show_all)

      (show_all ? label : box).allocate(width, height, baseline)
    end
  end

  def label
    @label ||= Gtk::Label.new(@text).tap do |l|
      l.xalign = 0.0
      l.yalign = 0.0
      l.wrap = true
      l.width_chars = 3
      l.max_width_chars = 30
    end
  end

  def box = @box ||= Gtk::Box.new(:vertical, 0).tap { |b| b.vexpand = false }

  def inscription
    @inscription ||= Gtk::Inscription.new(@text).tap do |i|
      i.xalign = 0.0
      i.yalign = 0.0
      i.min_lines = 3
      i.nat_chars = 30
      i.vexpand = true
    end
  end

  def button = @button ||= Gtk::Button.new(label: 'Read More')

  private

  def opposite(orientation) = orientation.nick == 'horizontal' ? :vertical : :horizontal

  def fits?(child, orientation, for_size)
    for_size >= 0 && child.measure(opposite(orientation), -1).first <= for_size
  end

  def smaller_of(first, second)
    [[first[0], second[0]].min, [first[1], second[1]].min, -1, -1]
  end

  def showing_all_text?(width, height)
    @show_more || label.measure(:vertical, width).first <= height
  end
end

class ReadMoreDemo
  TEXT = <<~TEXT.freeze
    I'd just like to interject for a moment. What you're referring to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.

    Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called "Linux", and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.

    There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called "Linux" distributions are really distributions of GNU/Linux.
  TEXT

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Read More'
          win.child = read_more
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.read_more', :default_flags)
  def window = @window ||= Gtk::Window.new
  def read_more = @read_more ||= ReadMore.new(TEXT)
end

ReadMoreDemo.new.build.run
