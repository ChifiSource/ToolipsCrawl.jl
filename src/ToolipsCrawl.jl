module ToolipsCrawl
using Toolips
using Toolips.Crayons
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
        println("hello")
        comp = crawler.components[prop]
        lnk = comp["href"]
        push!(crawler.addresses, comp["href"])
    end for prop in allprops]
end

function crawl(f::Function, address::String)
    crawler::Crawler = Crawler(address)
    crawler.crawling = true
    println(Crayon(foreground = Symbol("light_magenta"), bold = true), "Crawler: crawler started at $address")
    @async while crawler.crawling
        crawl!(crawler)
        f(crawler)
        if length(crawler.addresses) < 1
            crawler.crawling = false
            println(Toolips.Crayon())
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

export scrape, crawl, kill

end # module ToolipsCrawl
