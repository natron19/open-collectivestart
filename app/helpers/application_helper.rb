module ApplicationHelper
  def flash_bootstrap_class(type)
    { "notice" => "success", "alert" => "danger", "info" => "info", "warning" => "warning" }
      .fetch(type.to_s, "secondary")
  end

  def markdown(text)
    return "" if text.blank?
    renderer = Redcarpet::Render::HTML.new(safe_links_only: true, no_images: true)
    Redcarpet::Markdown.new(renderer, autolink: true, tables: false).render(text).html_safe
  end
end
