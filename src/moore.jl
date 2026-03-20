function get_moore(url::AbstractString="https://www.sonnymoorepowerratings.com/w-basket.htm")
    resp = HTTP.get(url)
    if HTTP.Messages.iserror(resp)
        throw(HTTP.Messages.statustext(resp.status))
    end
    return String(resp.body)
end

function parse_moore_html(html::AbstractString)
    # the text is very simple to parse:
    # "  1 CONNECTICUT                 34    0    0   72.87  106.20\n"
    # This repeats twice on the page: once in rank order, once in alphabetical order.
    # Detect the switch by remembering the rank.
    regex = r"^\s*(\d+)\s+(.*?)\s+\d{1,2}\s+\d{1,2}\s+\d{1,2}\s+[0-9.]+\s+([0-9.]+)\s*$"m
    ratings = Tuple{String, Float64}[]
    rank = 0
    for m in eachmatch(regex, html)
        r = parse(Int, m.captures[1])
        if r <= rank
            break
        end
        rank = r
        push!(ratings, (m.captures[2], parse(Float64, m.captures[3])))
    end

    return ratings
end