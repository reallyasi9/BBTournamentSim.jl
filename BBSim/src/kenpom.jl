function get_kenpom(url::AbstractString="https://kenpom.com/")
    resp = HTTP.get(url)
    if HTTP.Messages.iserror(resp)
        throw(HTTP.Messages.statustext(resp.status))
    end
    return String(resp.body)
end

function is_ratings_table(elem::HTMLNode)
    return tag(elem) == :table && getattr(elem, "id", "") == "ratings-table"
end

is_ratings_table(::HTMLText) = false

function parse_team_row(elem::HTMLNode)
    if tag(elem) != :tr
        return nothing
    end
    if length(Gumbo.children(elem)) < 5
        return nothing
    end
    if getattr(elem, "class", "") ∉ ("bold-bottom", "")
        return nothing
    end
    team_name = text(elem[2][1]) # 2nd td, a tag within
    team_rating = parse(Float64, text(elem[5])) # adjusted efficiency margin

    return (team_name, team_rating)
end

parse_team_row(::HTMLText) = nothing

function parse_kenpom_html(html::AbstractString)
    doc = parsehtml(html)

    ratings_table = first(filter(is_ratings_table, collect(PreOrderDFS(doc.root))))
    if isnothing(ratings_table)
        throw(ErrorException("no table element with id='rataings-table' found"))
    end

    ratings = filter(!isnothing, parse_team_row.(PreOrderDFS(ratings_table)))

    return ratings
end