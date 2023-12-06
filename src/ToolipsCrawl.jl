module ToolipsCrawl
using Toolips
using Toolips.Crayons
import ToolipsSession: htmlcomponent, kill!
import Base: getindex

mutable struct Crawler
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

export scrape, crawl, kill!, Crawler

end # module ToolipsCrawl
