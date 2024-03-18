function get_rpi(url::AbstractString="http://realtimerpi.com/ncaab/college_Women_basketball_power_rankings_Full.html")
    resp = HTTP.get(url)
    if HTTP.Messages.iserror(resp)
        throw(HTTP.Messages.statustext(resp.status))
    end
    return String(resp.body)
end

function is_rpi_table(elem::HTMLNode)
    try
        tag(elem) != :table && return false
        length(Gumbo.children(elem)) < 1 && return false # has tbody?
        tbody_elem = elem[1]
        tag(tbody_elem) == :tbody || return false
        length(Gumbo.children(tbody_elem)) < 1 && return false # has tr?
        tr_elem = tbody_elem[1]
        tag(tr_elem) == :tr || return false
        length(Gumbo.children(tr_elem)) < 1 && return false # has td?
        td_elem = tr_elem[1]
        tag(td_elem) == :td || return false
        length(Gumbo.children(td_elem)) < 1 && return false # has b
        b_elem = td_elem[1]
        tag(b_elem) == :b || return false
        length(Gumbo.children(b_elem)) < 1 && return false # has text?
        return text(b_elem) == "Rank"
    catch
        return false
    end
end

is_rpi_table(::HTMLText) = false

function parse_rpi_row(elem::HTMLNode)
    tag(elem) != :tr && return nothing
    length(Gumbo.children(elem)) < 6 && return nothing
    # 3rd td element contains text and an anchor with the school and team name
    # 5th td element contains the rating
    name_elem = elem[4]
    tag(name_elem) == :td || return nothing
    length(Gumbo.children(name_elem)) == 2 || return nothing
    a_elem = name_elem[2]
    tag(a_elem) == :a || return nothing
    team_name = text(a_elem)

    rating_elem = elem[6]
    tag(rating_elem) == :td || return nothing
    team_rating = parse(Float64, text(rating_elem))

    return (team_name, team_rating)
end

parse_rpi_row(::HTMLText) = nothing

function parse_rpi_html(html::AbstractString)
    doc = parsehtml(html)

    ratings_table = first(filter(is_rpi_table, collect(PreOrderDFS(doc.root))))
    if isnothing(ratings_table)
        throw(ErrorException("no table element found"))
    end

    ratings = filter(!isnothing, parse_rpi_row.(PreOrderDFS(ratings_table)))

    return ratings
end