module SiteUserRecordsHelper

  def sortable(column, params, title = nil)
    sort = params[:sort]
    direction = params[:direction]

    title ||= column.titleize
    direction = column == sort && direction == "desc" ? "asc" : "desc"
    css_class = column == sort ? "current #{direction}" : nil

    params_new = params.clone
    params_new[:sort] = column
    params_new[:direction] = direction
    link_to title, params_new, {:class => css_class}
  end

  def unsortable(column, params, title = nil)
    title ||= column.titleize
  end

end
