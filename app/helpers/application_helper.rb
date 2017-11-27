# Methods added to this helper will be available to all templates in
# the application.
module ApplicationHelper
  # This method provides help with the differences in how different browsers
  # show "tooltips". IE shows the :alt of the image. Firefox shows the
  # :title of the link.
  def link_with_image(img_filename, url_hash, options_hash)
    img = image_tag img_filename, :border => "0", :alt => options_hash[:title]
    link_to img, url_hash, options_hash
  end

  def text(*s)
    @controller.send :text, s
  end
end
