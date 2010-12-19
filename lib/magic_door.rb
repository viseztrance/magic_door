#
# = magic_door.rb - MagicDoor generator
#
# Author:: Daniel Mircea daniel@viseztrance.com
# Copyright:: Copyright (c) 2010 Daniel Mircea, OkapiStudio
# License:: MIT and/or Creative Commons Attribution-ShareAlike

require "RMagick"
require "fileutils"

class MagicDoor

  VERSION = Gem::Specification.load(File.expand_path("../magic_door.gemspec", File.dirname(__FILE__))).version.to_s

  module CssMethods #:nodoc:

    def set_properties(css)

      css.each do |args|
        attribute = MagicDoor::CSS_ALIASES[:attributes][args.first] || args.first
        value = proc {
          v = MagicDoor::CSS_ALIASES[:values][args.last] || args.last
          Float(v) rescue v
        }.call
        self.send("#{attribute}=", value)
      end

    end

  end

  CSS_ALIASES = {

    :attributes => {
      "color"       => "fill",
      "font-weight" => "font_weight",
      "font-family" => "font_family",
      "font-size"   => "pointsize",
      "text-align"  => "gravity",
    },

    :values => {
      "bold"   => Magick::BoldWeight,
      "center" => Magick::CenterGravity,
      "left"   => Magick::WestGravity,
      "right"  => Magick::EastGravity
    }

  }

  attr_reader           :css,
                        :image


  attr_accessor         :text,
                        :split_at,
                        :source_path,
                        :destination_path,
                        :file_name

  attr_accessor         :canvas #:nodoc:

  @@defaults = {
    :css              => "text-align: center; padding: 10; color: #000",
    :split_at         => 30,
    :image            => "button.png",
    :source_path      => "",
    :destination_path => "",
    :text             => "Submit",
    :file_name        => "result.png"
  }

  class << self

    # Sets +defaults+ for new object instances.
    def defaults=(options)
      @@defaults = options
    end

    # Returns defined defaults
    def defaults
      @@defaults
    end

  end

  # Instantiate a new object.
  # Missing options fallback to +defaults+.
  # ==== Options:
  # [*text*] Text that will be displayed inside the button.
  # [*split_at*] Location where the image is being split.
  # [*source_path*] Prefix for +image+ location.
  # [*destination_path*] Prefix for +file_name+ location.
  # [*file_name*] The name of the file being saved.
  def initialize(options = {})
    self.css = self.class.defaults[:css]
    self.css = options[:css] if options[:css]
    %w(source_path destination_path split_at image text file_name).each do |name|
      n = name.to_sym
      self.send("#{n}=", options[n] || self.class.defaults[n])
    end
  end

  # Creates the image file.
  # ==== Returns
  # Path of the saved file.
  # ==== Options
  # [*as*] Alternate way of setting the name of the file being saved. Fallsback to +file_name+.
  def save(options = {})
    compose_button
    draw
    write_file(options[:as] || file_name)
  end

  # Sets the template image.
  #
  # Will fail if the image does not exist.
  def image=(name)
    @image = Magick::Image.read(File.join(source_path, name)).first
  end

  # Evaluates CSS expressions.
  #
  # Gracefuly merges the CSS defined in +defaults+.
  #
  # Sizes are being calculated in pixels. Don't specify any measuring units at all.
  # ==== Available expressions:
  # * color
  # * font-weight
  # * font-family
  # * font-size
  # * text-align
  # * padding
  # * width
  # * height
  # * left
  # * right
  def css=(expressions)

    values = { :container => [], :shadow => [], :text => [] }

    expressions.to_s.delete("\n").split(";").each do |expression|

      args = expression.split(":").each { |arg| arg.strip! }

      if %w(width height padding left right).include?(args.first)
        values[:container] << args
      elsif args.first == "text-shadow"
        values[:shadow] << args
      else
        values[:text] << args
      end

    end

    @css ||= {}
    @css.merge!(values) { |key, old, new|
      keys = new.collect { |e| e.first }
      old.each { |e| new << e unless keys.index(e.first) }
      new
    }

  end

  def canvas #:nodoc:
    @canvas ||= proc {
      padding = (get_css_property(css[:container], "padding") || text_width).to_i
      width   = (get_css_property(css[:container], "width") || text_width).to_i + padding
      height  = (get_css_property(css[:container], "height") || image.rows).to_i
      Magick::Image.new(width, height) { self.background_color = "none" }
    }.call
  end

  private

  def draw
    drawing = Magick::Draw.new
    drawing.extend(CssMethods)
    drawing.set_properties(css[:text])
    margin_left = (get_css_property(css[:container], "left")).to_i
    margin_right = (get_css_property(css[:container], "right")).to_i
    margin = margin_left - margin_right
    if !css[:shadow].empty?
      args         = css[:shadow].first.last.split
      drawing.fill = args.first
      drawing.annotate(self.canvas, 0, 0, margin + args[1].to_i, args[2].to_i, text)
      drawing.fill = get_css_property(css[:text], "color")
    end
    drawing.annotate(self.canvas, 0, 0, margin, 0, text)
  end

  def get_css_property(stack, key)
    stack.reject { |c| c.first != key }.flatten.last
  end

  def compose_button
    main_image = image.crop(Magick::EastGravity, (canvas.columns - split_at), canvas.rows)
    left_image = image.crop(Magick::WestGravity, split_at, canvas.rows)
    self.canvas.composite!(main_image, left_image.columns, 0, Magick::OverCompositeOp)
    self.canvas.composite!(left_image, Magick::WestGravity, Magick::OverCompositeOp)
  end

  def write_file(name)
    FileUtils.mkdir_p destination_path unless destination_path.empty?
    save_path = File.join(destination_path, name)
    canvas.write(save_path)
    save_path
  end

  def text_width(offset = 6)
    temporary_canvas = Magick::Image.new(1000, 150)
    drawing = Magick::Draw.new
    drawing.extend(CssMethods)
    drawing.set_properties(css[:text])

    return (drawing.get_type_metrics(temporary_canvas, text)["width"] + offset)

  end

end
