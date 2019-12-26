#  NarouFetcher

This project is for fetching light novel contents from [小説家になろう](https://syosetu.com) site. API is based on [なろうデベロッパー](https://dev.syosetu.com/man/api/) site.

### Status
**Under experimenting**, don't even think about using on your project.  This project may be abandoned any time.  

###  Usage

```.swift
import NarouFetcher

	// ...

	let keyword = "魔王"
	let fetcher = NarouFetcher.shared
	fetcher.query(parameters: [
		NarouFetcher.検索単語指定(keyword),
		NarouFetcher.検索対象範囲指定(.あらすじ),
		NarouFetcher.検索対象範囲指定(.タイトル),
		NarouFetcher.最終掲載日指定(.先月),
//		NarouFetcher.ピックアップ指定()
	]) { (response, error) in
		if let response = response {
			for entry in response.entries {
				print("ncode:", entry.Nコード ?? "nil")
				print("title:", entry.タイトル ?? "nil")
			}
		}
	}
```

### Environment

```.console
Version 11.3 (11C29)
Apple Swift version 5.1.3 (swiftlang-1100.0.282.1 clang-1100.0.33.15)
Target: x86_64-apple-darwin19.2.0
```
