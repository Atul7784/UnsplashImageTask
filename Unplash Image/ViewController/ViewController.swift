import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Properties
    var imageUrls: [URL] = []
    let imageCache = NSCache<NSString, UIImage>()
    var currentPage = 1
    var isFetching = false
    // MARK: - Viewcontroller Lifecycele
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchImages()
    }


    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell

        let imageUrl = imageUrls[indexPath.item]
        cell.imageView.image = nil
        if let cachedImage = imageCache.object(forKey: imageUrl.absoluteString as NSString) {
                cell.imageView.image = cachedImage
            } else {
                // Asynchronously load image
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: data) {
                        // Cache loaded image
                        self.imageCache.setObject(image, forKey: imageUrl.absoluteString as NSString)
                        // Update UI on the main thread
                        DispatchQueue.main.async {
                            cell.imageView.image = image
                        }
                    } else {
                        // If image loading fails, set a placeholder image
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage(named: "FailImage")
                        }
                    }
                }
            }

        if indexPath.item == imageUrls.count - 1 {
            currentPage += 1
            fetchImages()
        }

        return cell
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width) / 3.1 // Adjust for spacing
        return CGSize(width: width, height: width)
    }
}
extension ViewController{
    //MARK: - Fetch Image Api
    func fetchImages() {
        guard !isFetching else { return } 
        isFetching = true

        let urlString = "https://api.unsplash.com/photos?page=\(currentPage)&client_id=LvX2Pe42I-CUY_uvfduM2luM67Gd4WTEHibxhNMLaMY"
        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Error fetching images: \(error?.localizedDescription ?? "Unknown error")")
                self?.isFetching = false
                return
            }

            do {
                let decoder = JSONDecoder()
                let photos = try decoder.decode([UnsplashPhoto].self, from: data)
                let newImageUrls = photos.compactMap { URL(string: $0.urls.regular) }
                self?.imageUrls.append(contentsOf: newImageUrls)

                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }

            self?.isFetching = false
        }
        task.resume()
    }

}

