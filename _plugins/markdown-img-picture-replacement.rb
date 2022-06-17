# Description: Jekyll plugin to replace Markdown image syntax with {% picture %} tag for crafting responsive images

Jekyll::Hooks.register :posts, :pre_render do |post, payload|
  docExt = post.extname.tr('.', '')
  # only process if we deal with a markdown file
  if payload['site']['markdown_ext'].include? docExt
    newContent = post.content.gsub(/\!\[(.+)\]\((.+)\)/, '{% picture default \2 alt="\1" %}')
    post.content = newContent
  end
end