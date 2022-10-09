# Wording

## Motivation

Working with `.strings` files based localization is always a bit tricky (at least for me):  
- It is not type safe and error prone approach where you should always double check strings you type in  
- There's no way for changing translations on the fly in production, assume you made a typo and want to fix it ASAP, all you can do is fix it in bundled `.strings` and wait until new release  
- Also it's always a big mess regarding namespacing, you have to deal with long names or separate tables to achieve unique keys  

I was always working dealing with `.yml` files wherever it's possible, so here's a small tool that solves all the problems described above  

## Example

Assume this is your `Localizable.strings` file:  

```bash
/* Home */
"home.tabs.feed" = "Feed";
"home.tabs.projects" = "My projects";

/* Feed */
"feed.title" = "See what's new";

/* Projects */
"projects.title" = "My projects";

/* Common */
"common.close" = "Close";
"common.cancel" = "Cancel";
"common.delete" = "Delete";
```

A lot of unnecessary code duplication and symbols (well, not big deal here, but in big project it will be much worse)?  
This structure always look like a tree, so why not to describe it in a more appropriate way?  

This is what `wording.yml` can be look like:  

```yml
home:
  tabs:
    feed: Feed
    projects: My projects
feed:
  title: See what's new
projects:
  title: My projects
common:
  close: Close
  cancel: Cancel
  delete: Delete
```

This file will be generated automatically during the build process every time you edit your `wording.yml` file(s)  

```swift
import Wording

public enum Wording: Wordingable {
    fileprivate static var wording = [String: String]()

    public static func complement(using wording: [String: Any]) {
        complement(using: wording, path: nil)
    }

    private static func complement(using wording: [String: Any], path: String?) {
        for (key, value) in wording {
            let path = [path, key]
                .compactMap { $0 }
                .joined(separator: ".")

            if let leaf = value as? String {
                Self.wording[path] = leaf
            } else if let node = value as? [String: Any] {
                complement(using: node, path: path)
            }
        }
    }
}

extension Wording {
    public enum Home {
        public enum Tabs {
            public static var feed: String { leaf("home.tabs.feed") }
            public static var projects: String { leaf("home.tabs.projects") }
        }
    }

    public enum Feed {
        public static var title: String { leaf("feed.title") }
    }

    public enum Projects {
        public static var title: String { leaf("projects.title") }
    }

    public enum Common {
        public static var close: String { leaf("common.close") }
        public static var cancel: String { leaf("common.cancel") }
        public static var deelete: String { leaf("common.deelete") }
    }
}

private func leaf(_ path: String) -> String {
    guard let leafValue = Wording.wording[path] else {
        assertionFailure("No wording value for \(path)")
        return ""
    }

    return leafValue
}
```

After that you can simply type `Wording.Home.Tabs.feed` in your code with full IDE code autocompletion support  

Much better, right? 🙂  

## Usage

In order to replace `.strings` based localization to `.yml` based follow these few steps:  
- Add package dependency to your package with your `yml` localization resources  

```bash
.package(url: "https://github.com/kutchie-pelaez-packages/Wording.git", branch: "master")

```

- Add target dependency to your target with localization resources  

```bash
.product(name: "Wording", package: "Wording")

```

- Add plugin dependency to your target with localization resources  

```bash
.plugin(name: "WordingGenerationPlugin", package: "Wording")
```

- Hit `cmd+B` to check everything works properly, plugin should generate `Wording.swift` file in build directory with structure based on your `wording_en.yml` file (or any first `wording....yml` file it found)  

At some point you'll need a `WordingManager` instance to configure your wording:  
- Create an instance of `WordingManager` through public interface of `WordingManagerFactory` somewhere at the start of your app and call `start()` method  
- You'll also need to create a `WordingManagerProvider` instance in order to provide wording urls to work with  
