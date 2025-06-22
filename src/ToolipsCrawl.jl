"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.
### ToolipsCrawl
**ToolipsCrawl** provides a high-level web-scraping and web-crawling interface using the 
`Toolips` web-development framework's requests and `Component` structures.
```julia
using ToolipsCrawl
titles = []
crawl("https://chifidocs.com") do crawler::Crawler
    titles = get_by_tag(crawler, "title")
    if length(titles) > 0
        @info "scraped title from " * crawler.address
        push!(titles, titles[1][:text])
    end
end
```
##### Module Composition
- **ToolipsCrawl**
- `AbstractCrawler`
- `Crawler`
- `scrape!`
- `crawl!`
- `try_scrape_recursive!`
- `scrape`
- `crawl`
- `kill!(::Crawler)`
- `get_by_name`
- `get_by_tag`
"""
module ToolipsCrawl
using Toolips
using Toolips.Crayons
using Toolips.Components
import Toolips.Components: gen_ref
import Base: getindex

"""
```julia
abstract type AbstractCrawler
```
An `AbstractCrawler` is a web-crawler which can be crawled to using `crawl` and scraped using `scrape`.

- addresses::Vector{String}
- crawling::Bool
- components::Vector{Servable}
"""
abstract type AbstractCrawler end

"""
```julia
Crawler <: AbstractCrawler
```
- address**::String**
- crawling**::Bool**
- addresses**::Vector{String}**
- components**::Vector{Servable}**
The `Crawler` is created by the functions `crawl` and `scrape` and stores components from addresses while navigating 
to new ones while crawling.  A `Crawler` will be passed through a `Function` provided to `scrape` or `crawl` as an argument. 
Indexing with a `String` will yield the `Component` by that name. A `Crawler` may be stopped with `kill!`. 
For more information on `scrape` or `crawl`, see `?scrape` and `?crawl` respectively. Crawlers may also be 
filtered using `ComponentFilters`. We are able to filter by getting index with a filter and a value to filter with.
This allows us to get elements by name, by tag, or elements that contain a certain property.
```example
using ToolipsCrawl
using ToolipsCrawl.Components
rows = []
scrape("https://github.com/ChifiSource") do c::Crawler
    current_rows = get_by_tag(c, "td")
    for row::Component{:td} in current_rows
        push!(rows, row[:text])
    end
end
```
```julia
using ToolipsCrawl
titles = []
crawl("https://chifidocs.com") do crawler::Crawler
    titles = get_by_tag(crawler, "title")
    if length(titles) > 0
        @info "scraped title from " * crawler.address
        push!(titles, titles[1][:text])
    end
end
```
For more information on these filters, see `?ComponentFilters`
```julia
Crawler(address::String)
```
"""
mutable struct Crawler <: AbstractCrawler
    address::String
    crawling::Bool
    addresses::Vector{String}
    raw::String
    Crawler(address::String) = new(address, false, Vector{String}(), "")
end

getindex(c::Crawler, name::String) = getindex(c.components, name)

"""
```julia
scrape!(::Crawler) -> ::Crawler
```
Scrapes the current crawler; performs the core GET request and updates 
`Crawler.raw`.
"""
function scrape!(crawler::Crawler)
    crawler.raw = Toolips.get(crawler.address)
    crawler
end

"""
```julia
crawl!(crawler::Crawler) -> ::Nothing
```
`crawl!` will search for new available addresses to crawl to inside of `Crawler.raw`. This 
    is done after scraping with `scrape!` whenever we are crawling with `crawl`. Note that 
    the mutating equivalents, `scrape!` and `crawl!`, are not usually called directly.
See also: `crawl`, `scrape!`, `Crawler`, `ToolipsCrawl`
"""
function crawl!(crawler::Crawler)
    allprops = findall("href=\"", crawler.raw)
    for proplocation in allprops
        start = maximum(proplocation) + 1
        href_link_end = findnext("\"", crawler.raw, start)
lnk = try
	crawler.raw[start:prevind(crawler.raw, maximum(href_link_end))]
catch
	try
		crawler.raw[start:prevind(crawler.raw, maximum(href_link_end), 2)]
	catch
		crawler.raw[prevind(crawler.raw, start):prevind(crawler.raw, maximum(href_link_end), 2)]
	end
end

        if contains(lnk, ".jpg") || contains(lnk, ".png")
            continue
        elseif ~(contains(lnk, "http"))
            continue
        end
        push!(crawler.addresses, lnk)
    end
    nothing::Nothing
end

"""
```julia
scrape(f::Function, address::String) -> ::Nothing
```
Scrapes `address`, providing a `Crawler` with components from `Address` to `f`.
```example
scrape("https://chifidocs.com") do crawler::Crawler
    header = get_by_id(crawler, "welcome-1")
    @info header[1][:text]
end
```
"""
function scrape(f::Function, address::String)
    crawler::Crawler = Crawler(address)
    f(scrape!(crawler))
    nothing::Nothing
end

"""
```julia
try_scrape_recursive!(crawler::Crawler) -> ::Bool
```
Continues to scrape addresses in `Crawler.addresses` recursively until one works. 
Returns a `Bool`; `true` means that a page was successfully scraped and `false` means 
we ran out of addresses. This is used internally by `crawl` so that errors aren't produced anytime 
a broken or dead URL is provided.
"""
function try_scrape_recursive!(crawler::Crawler)
    try
        scrape!(crawler)
    catch
        if length(crawler.addresses) == 1
            return(false)
        end
        deleteat!(crawler.addresses, 1)
        crawler.address = crawler.addresses[1]
        return(try_scrape_recursive!(crawler))
    end
    true
end

"""
```julia
crawl(f::Function, ...; ...) -> ::Nothing
```
`crawl` scrapes `address` using `scrape!`, crawls using `crawl!` then calls `f` on the `Crawler`. Next, it crawls to addresses found on 
that page, repeating the function call until `kill!` is used or there are no remaining addresses. We may also provide multiple addresses. 
`show_address` determines whether or not the crawler should print each address on request.
```julia
crawl(f::Function, address::String; show_address::Bool = false) -> ::Crawler
crawl(f::Function, address::String; keys ...) -> ::Crawler
crawl(f::Function, address::String ...; keyargs ...)
```
```example
using ToolipsCrawl
titles = []
crawl("https://chifidocs.com") do crawler::Crawler
    titles = get_by_tag(crawler, "title")
    if length(titles) > 0
        @info "scraped title from " * crawler.address
        push!(titles, titles[1][:text])
    end
end
```
"""
function crawl(f::Function, crawler::Crawler; show_address::Bool = false)
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    while crawler.crawling
        if show_address
            println(crawler.address)
        end
        success = try_scrape_recursive!(crawler)
        if ~(success)
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true), "Crawler: crawler stopped (out of addresses)")
            break
        end
        crawl!(crawler)
        try
            f(crawler)
        catch e
            crawler.crawling = false
            throw(e)
        end
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true), "Crawler: crawler stopped (out of addresses)")
            break
        end
        crawler.address = crawler.addresses[1]
        deleteat!(crawler.addresses, 1)
    end
end

crawl(f::Function, address::String; keys ...) = crawl(f, Crawler(address); keys ...)

function crawl(f::Function, address::String ...; keyargs ...)
    crawler::Crawler = Crawler(address[1])
    crawler.addresses = [address[2:end] ...]
    crawl(f, crawler; keyargs ...)
end

"""
```julia
kill!(crawler::Crawler) -> ::Nothing
```
Stops an active `Crawler`.
- See also: `get_by_tag`, `crawl`, `crawl!`, `Crawler`, `get_by_name`
"""
kill!(crawler::Crawler) = begin
    crawler.crawling = false
    println(Crayon(foreground = Symbol("light_red"), bold = true, blink = true), "Crawler: crawler stopped")
end

"""
```julia
get_by_tag(crawler::Crawler, tag::String) -> ::Vector{AbstractComponent}
```
Creates a `Vector` of components from the page currently being scraped, each `Component` 
will have the tag `tag`. This is meant to be called within a `Function` provided to `scrape` or 
`crawl`.
```julia
crawl("https://chifidocs.com") do crawler::Crawler
    titles = get_by_tag(crawler, "title")
    if length(titles) > 0
        push!(titles, titles[1][:text])
    end
end
```
"""
function get_by_tag(crawler::Crawler, tag::String)
    positions = findall("<$tag", crawler.raw)
    tagsymb = Symbol(tag)
    components = Vector{AbstractComponent}()
    for pos in positions
        arg_start = maximum(pos) + 2
        stop_tag::Int64 = maximum(findnext(">", crawler.raw, arg_start))
        tagend = findnext("</$tag>", crawler.raw, stop_tag)
        propsplits = split(crawler.raw[arg_start:stop_tag - 1], "\" ")
        comp = Component{tagsymb}("-")
        
        if isnothing(tagend)
            text = ""
        else
            text = crawler.raw[stop_tag + 1:minimum(tagend) - 1]
        end
        for prop in propsplits
            keyval = split(replace(prop, "\"" => ""), "=")
            if length(keyval) == 1
                continue
            end
            push!(comp.properties, Symbol(keyval[1]) => keyval[2])
        end
        comp[:text] = text
        push!(components, comp)
    end
    return(components)::Vector{AbstractComponent}
end

"""
```julia
get_by_name(crawler::Crawler, name::String) -> ::Vector{AbstractComponent}
```
Creates a `Vector` of components from the page currently being scraped, will only grab components with a specific ID.
 This is meant to be called within a `Function` provided to `scrape` or 
`crawl`.
```julia
scrape("https://chifidocs.com") do crawler::Crawler
    header = get_by_id(crawler, "welcome-1")
    @info header[1][:text]
end
```
See also: `get_by_tag`, `crawl`, `scrape`, `Crawler`, `ToolipsCrawl`
"""
function get_by_name(crawler::Crawler, name::String)
    raw = crawler.raw
    found_positions = findall("id=\"$component_name\"", raw)
    if isnothing(found_position) || length(found_position) == 0
        return(Vector{AbstractComponent}())
    end
    components = Vector{AbstractComponent}()
    for found_position in found_positions
        tag_begin::UnitRange{Int64} = findprev("<", raw, found_position)
        stop_tag::Int64 = maximum(findnext(">", raw, found_position))
        tag::Symbol = Symbol(raw[minimum(tag_begin) + 1:found_position - 2])
        tagend = findnext("</$tag>", raw, found_position)
        if isnothing(tagend)
            text = ""
        else
            text::String = raw[stop_tag + 1:minimum(tagend) - 1]
        end
        text = rep_in(text)
        splits::Vector{SubString} = split(raw[found_position:stop_tag], "\" ")
        push!(components, Component{tag}(component_name, text = text, [begin
            splits = split(property, "=")
            if length(splits) < 2
                "" => ""
            else
                replace(string(splits[1]), "\"" => "", ">" => "", "<" => "") => replace(string(splits[2]), 
                "\"" => "", ">" => "", "<" => "")
            end
        end for property in splits] ...))
    end
    components::Vector{AbstractComponent}
end

export crawl, scrape, Crawler, get_by_tag, get_by_name
end