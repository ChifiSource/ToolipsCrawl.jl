using ToolipsCrawl
using Test
@testset "Toolips Crawl" verbose = true begin
    @testset "Base Crawler" begin
        c = Crawler("http://github.com")
        @test typeof(c) == Crawler
        @test c.raw == ""
        @test c.crawling == false
        @test typeof(c) <: ToolipsCrawl.AbstractCrawler
    end
    @testset "scrape getbyid" begin
        scrape("https://chifidocs.com") do crawler::Crawler
            header = get_by_name(crawler, "welcome-1")
            @test header[1][:text] == "chifi docs"
        end
    end
    @testset "crawl getbytag" begin
        titles = []
        crawler = crawl("https://chifidocs.com", async = true) do crawler::Crawler
            title_comps = get_by_tag(crawler, "title")
            if length(title_comps) > 0
                push!(titles, title_comps[1][:text])
            end
        end
        sleep(2)
        @test length(titles) > 0
        @test "chifi docs" in titles
        kill!(crawler)
        @test crawler.crawling == false
        crawler = Crawler("https://chifidocs.com")
        titles = []
        
        crawl(crawler, async = true) do crawler::Crawler
            title_comps = get_by_tag(crawler, "title")
            if length(title_comps) > 0
                push!(titles, title_comps[1][:text])
            end
        end
        sleep(2)
        @test crawler.crawling
        @test length(titles) > 0
        kill!(crawler)
        len = length(titles)
        @test crawler.crawling == false
        sleep(1)
        @test length(titles) == len
    end
end