//
//  ViewController.swift
//  PrefetchingImages
//
//  Created by Andrey Gordeev on 2/13/17.
//  Copyright © 2017 Andrey Gordeev (andrew8712@gmail.com). All rights reserved.
//

import UIKit

struct Model {
    let urlString: String
    lazy var url: URL = {
        // I know it's unsafe.
        return URL(string: self.urlString)!
    }()
    var image: UIImage?

    init(urlString: String) {
        self.urlString = urlString
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var items =
        [Model(urlString: "http://www.gstatic.com/webp/gallery/1.jpg"),
         Model(urlString: "http://www.gstatic.com/webp/gallery/2.jpg"),
         Model(urlString: "http://www.gstatic.com/webp/gallery/3.jpg"),
         Model(urlString: "http://www.gstatic.com/webp/gallery/4.jpg"),
         Model(urlString: "http://www.gstatic.com/webp/gallery/5.jpg"),
         Model(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_06_l.jpg"),
         Model(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_07_l.jpg"),
         Model(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_08_l.jpg"),
         Model(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_09_l.jpg"),
         Model(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_10_l.jpg"),
         Model(urlString: "https://www.gstatic.com/webp/gallery3/1.png"),
         Model(urlString: "https://www.gstatic.com/webp/gallery3/2.png"),
         Model(urlString: "https://www.gstatic.com/webp/gallery3/3.png"),
         Model(urlString: "https://www.gstatic.com/webp/gallery3/4.png"),
         Model(urlString: "https://www.gstatic.com/webp/gallery3/5.png")]

    /// We store all ongoing tasks here to avoid duplicating tasks.
    fileprivate var tasks = [URLSessionTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.prefetchDataSource = self
    }

    // MARK: - Image downloading

    fileprivate func downloadImage(forItemAtIndex index: Int) {
        let url = items[index].url
        guard tasks.index(where: { $0.originalRequest?.url == url }) == nil else {
            // We're already downloading the image.
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.items[index].image = image
                    let indexPath = IndexPath(row: index, section: 0)
                    if self.tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }
                }
            }
        }
        task.resume()
        tasks.append(task)
    }

    fileprivate func cancelDownloadingImage(forItemAtIndex index: Int) {
        let url = items[index].url
        guard let taskIndex = tasks.index(where: { $0.originalRequest?.url == url }) else {
            return
        }
        let task = tasks[taskIndex]
        task.cancel()
        tasks.remove(at: taskIndex)
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)

        if let imageView = cell.viewWithTag(100) as? UIImageView {
            if let image = items[indexPath.row].image {
                imageView.image = image
            } else {
                imageView.image = nil
                self.downloadImage(forItemAtIndex: indexPath.row)
            }
        }
        return cell
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetchRowsAt \(indexPaths)")
        indexPaths.forEach { self.downloadImage(forItemAtIndex: $0.row) }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("cancelPrefetchingForRowsAt \(indexPaths)")
        indexPaths.forEach { self.cancelDownloadingImage(forItemAtIndex: $0.row) }
    }
}
