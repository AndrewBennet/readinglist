import Foundation
import SwiftUI
import UIKit
import Combine
import CoreData

class BookDetailsHostingController: UIHostingController<BookDetailsContainer> {
    private var bookContainer = BookContainer()
    private var cancellables = Set<AnyCancellable>()

    init(_ book: Book) {
        super.init(rootView: BookDetailsContainer(bookContainer: bookContainer))
        bookContainer.book = book
        registerDeletionObserver()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: BookDetailsContainer(bookContainer: bookContainer))
        registerDeletionObserver()
    }

    private func registerDeletionObserver() {
        PersistentStoreManager.container.viewContext.deletedObjectsPublisher().sink { [weak self] ids in
            guard let self = self, let book = self.bookContainer.book else { return }
            if ids.contains(book.objectID) {
                self.bookContainer.book = nil
                self.splitViewController?.masterNavigationController.popViewController(animated: false)
                self.configureNavigationItem()
            }
        }.store(in: &cancellables)
    }

    func setBook(_ book: Book?) {
        bookContainer.book = book
        configureNavigationItem()
    }

    private func configureNavigationItem() {
        if bookContainer.book != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItem()
    }

    @objc private func shareButtonTapped() {
        guard let book = bookContainer.book else { return }
        let sharedText = "\(book.titleAndSubtitle)\n\(book.authors.fullNames)"
        let activityViewController = UIActivityViewController(activityItems: [sharedText], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        activityViewController.excludedActivityTypes = [.assignToContact, .saveToCameraRoll, .addToReadingList,
                                                        .postToFlickr, .postToVimeo, .openInIBooks, .markupAsPDF]

        present(activityViewController, animated: true, completion: nil)
    }
}

class BookContainer: ObservableObject {
    @Published var book: Book?
}

struct BookDetailsContainer: View {
    @ObservedObject var bookContainer: BookContainer

    var body: some View {
        Group {
            if let book = bookContainer.book {
                BookDetails(book: book)
            } else {
                EmptyView()
            }
        }
    }
}
