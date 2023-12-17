"""
Created in Decenmber, 2022
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
- This software is MIT-licensed.
### ToolipsCrawl
**ToolipsCrawl** provides a high-level web-scraping and web-crawling interface using the 
`Toolips` web-development framework's requests and `Component` structures. The package also 
featurs `ComponentFilters`, a set of premade filters for scraped components. See `?Crawler` for 
usage
##### Module Composition
- **ToolipsCrawl**
- **ComponentFilters**
"""
module ToolipsCrawl
using Toolips
using Toolips.Crayons
import ToolipsSession: htmlcomponent, kill!
import Base: getindex, get

"""
### abstract type AbstractCrawler
An `AbstractCrawler` is a web-crawler which can be crawled to using `crawl` and scraped using `scrape`.
##### Consistencies
- addresses::Vector{String}
- crawling::Bool
- components::Vector{Servable}
"""
abstract type AbstractCrawler end

"""
### Crawler <: AbstractCrawler
- address**::String**
- crawling**::Bool**
- addresses**::Vector{String}**
- components**::Vector{Servable}**
---
The `Crawler` is created by the functions `crawl` and `scrape` and stores components from addresses while navigating 
to new ones while crawling.  A `Crawler` will be passed through a `Function` provided to `scrape` or `crawl` as an argument.
```example
using ToolipsCrawl
subtitletxt = scrape("https://github.com/ChifiSource/ToolipsCrawl.jl") do c::Crawler
    text = c["start-of-content"]["class"]
end
```
Indexing with a `String` will yield the `Component` by that name. For more information on `scrape` or `crawl`, see 
`?scrape` and `?crawl` respectively. Crawlers may also be filtered using `ComponentFilters`. 
This allows us to get elements by name, by tag, or elements that contain a certain property.
```example
using ToolipsCrawl
using Toolips
comps = scrape("https://github.com/ChifiSource") do c::Crawler
    comps = c[ComponentFilters.bytag, "img"]
    get(comps, ComponentFilters.has_property, "src")
end
```
For more information on these filters, see `?ComponentFilters`
---
##### constructors
- Crawler(address::String)
"""
mutable struct Crawler <: AbstractCrawler
    address::String
    crawling::Bool
    addresses::Vector{String}
    components::Vector{Servable}
    Crawler(address::String) = new(address, false, Vector{String}(), Vector{Servable}())
end

getindex(c::Crawler, name::String) = getindex(c.components, name)

function scrape!(crawler::Crawler)
    data::String = Toolips.get(crawler.address)
    crawler.components = htmlcomponent(data, nonames = true)
    crawler
end

function scrape!(crawler::Crawler, read::Vector{String})
    data::String = Toolips.get(crawler.address)
    crawler.components = htmlcomponent(data, read)
    crawler
end

function crawl!(crawler::Crawler)
    scrape!(crawler)
    allprops = findall(c::Component{<:Any} -> "href" in keys(c.properties), crawler.components)
    [begin
        comp = crawler.components[prop]
        lnk = comp["href"]
        if contains(lnk, "http")
            push!(crawler.addresses, comp["href"])
        elseif contains(lnk, "/")
            addend = findfirst("://", crawler.address)
            targetend = findnext("/", crawler.address, maximum(addend) + 1)
            push!(crawler.addresses, crawler.address[1:maximum(addend)] * crawler.address[maximum(addend) + 1:targetend[1] - 1] * lnk)
        end
    end for prop in allprops]
end

function crawl(f::Function, address::String; show_address::Bool = false)
    crawler::Crawler = Crawler(address)
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    @async while crawler.crawling
        if show_address
            println(crawler.address)
        end
        try
            crawl!(crawler)
        catch

        end
        try
            f(crawler)
        catch e
            break
            crawler.crawling = false
            throw(e)
        end
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true), "Crawler: crawler stopped")
            break
        end
        crawler.address = crawler.addresses[1]
        deleteat!(crawler.addresses, 1)
    end
    crawler::Crawler
end

function crawl(f::Function, address::String ...)
    crawler::Crawler = Crawler(address[1])
    crawler.addresses = [add for add in address[2:length(address)]]
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    @async while crawler.crawling
        crawl!(crawler)
        f(crawler)
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Crayon(foreground = Symbol("light_red"), bold = true, blink = true), "Crawler: crawler stopped")
            break
        end
        crawler.address = crawler.addresses[1]
        deleteat!(crawler.addresses, 1)
    end
    crawler::Crawler
end

function scrape(f::Function, address::String)
    crawler::Crawler = Crawler(address)
    f(scrape!(crawler))
end

function scrape(f::Function, address::String, components::String ...)
    crawler::Crawler = Crawler(address)
    f(scrape!(crawler, [components ...]))
end

kill!(crawler::Crawler) = begin
    crawler.crawling = false
    println(Crayon(foreground = Symbol("light_red"), bold = true, blink = true), "Crawler: crawler stopped")
end

module ComponentFilters
    using Toolips
    import Base: get

    mutable struct ComponentFilter{T <: Any}
        value::String
        ComponentFilter{T}(val::String) where {T <: Any} = new{Symbol(T)}(val)::ComponentFilter{<:Any}
    end    
    const bytag = ComponentFilter{:tag}("")
    const byname = ComponentFilter{:name}("")
    const has_property = ComponentFilter{:hasproperty}("")
    get(vec::Vector{Servable}, f::ComponentFilter{<:Any}, val::String) = begin
        f.value = val
        get(f, vec)
    end
    
    get(f::ComponentFilter{:tag}, comps::Vector{Servable}) = begin
        filter(comp -> comp.tag == f.value, comps)
    end
    get(f::ComponentFilter{:name}, comps::Vector{Servable}) = begin
        filter(comp -> comp.name == f.value, comps)
    end
    get(f::ComponentFilter{:hasproperty}, comps::Vector{Servable}) = begin
        filter(comp -> f.value in keys(comp.properties), comps)
    end
end

function getindex(c::Crawler, filt::ComponentFilters.ComponentFilter{<:Any}, val::String)
    get(c.components, filt, val)
end

get(c::Crawler, f::ComponentFilters.ComponentFilter{<:Any}, val::String) = get(c.components, f, val)


get(c::Crawler, f::ComponentFilters.ComponentFilter{<:Any}) = @info "this filter has no `get` binding. See `?ComponentFilters`"


export scrape, crawl, kill!, Crawler, ComponentFilters

end # module ToolipsCrawl
