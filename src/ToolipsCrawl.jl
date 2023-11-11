module ToolipsCrawl
using Toolips
import ToolipsSession: htmlcomponent, kill!

mutable struct Crawler
    address::String
    crawling::Bool
    addresses::Vector{String}
    components::Vector{Servable}
    Crawler(address::String) = new(address, false, Vector{String}(), Vector{Servable}())
end

function scrape!(crawler::Crawler)
    data::String = Toolips.get(crawler.address)
    crawler.components = htmlcomponent(data)
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
        push!(crawler.addresses, comp)
    end for prop in allprops]
    return
end

function crawl(f::Function, address::String)
    crawler::Crawler = Crawler(address)
    crawler.crawling = true
    Threads.@spawn while crawler.crawling
        crawl!(crawler)
        f(crawler)
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

kill!(crawler::Crawler) = crawler.crawling = false

export scrape, crawl, kill

end # module ToolipsCrawl
