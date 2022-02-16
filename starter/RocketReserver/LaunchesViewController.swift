//
//  LaunchesViewController.swift
//  RocketReserver
//
//  Created by Ellen Shapiro on 11/13/19.
//  Copyright © 2019 Apollo GraphQL. All rights reserved.
//

import UIKit
import SDWebImage
import Apollo

class LaunchesViewController: UITableViewController {
    enum ListSection: Int, CaseIterable {
      case launches
      case loading
    }
    
    var detailViewController: DetailViewController? = nil
    var launches = [LaunchListQuery.Data.Launch.Launch]()
    private var lastConnection: LaunchListQuery.Data.Launch?
    private var activeRequest: Cancellable?


    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMoreLaunchesIfTheyExist()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
        
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showProfile" {
            // This should always occur
            return true
        }
        
        guard let selectedIndexPath = self.tableView.indexPathForSelectedRow else {
            return false
        }
        
        guard let listSection = ListSection(rawValue: selectedIndexPath.section) else {
            assertionFailure("Invalid section")
            return false
        }
        
        switch listSection {
        case .launches:
            return true
        case .loading:
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            
            if self.activeRequest == nil {
                self.loadMoreLaunchesIfTheyExist()
            } // else, let the active request finish loading
            
            self.tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
            
            // In either case, don't perform the segue
            return false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            return
        }
    
        guard let selectedIndexPath = self.tableView.indexPathForSelectedRow else {
          return
        }
            
        guard let listSection = ListSection(rawValue: selectedIndexPath.section) else {
          assertionFailure("Invalid section")
          return
        }
            
        switch listSection {
        case .launches:
            guard let destination = segue.destination as? UINavigationController,
                  let detailViewController = destination.topViewController as? DetailViewController else {
                      assertionFailure("Wrong kind of destination")
                      return
                  }
            
            let launch = self.launches[selectedIndexPath.row]
            detailViewController.launchID = launch.id
            self.detailViewController = detailViewController
        case .loading:
            assertionFailure("Shouldn't have gotten here!")
        }
    }
    
    // MARK: - IBActions
    
    @IBAction private func launchTypeSelectorTapped(_ sender: UISegmentedControl) {
        // TODO: In the future, actually have this do something.
        sender.selectedSegmentIndex = 0
    }
    
    @IBAction private func profileTapped() {
        self.performSegue(withIdentifier: "showProfile", sender: nil)
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        ListSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listSection = ListSection(rawValue: section) else {
          assertionFailure("Invalid section")
          return 0
        }
              
        switch listSection {
        case .launches:
          return self.launches.count
        case .loading:
            let hasMore = self.lastConnection?.hasMore ?? false
            return hasMore ? 1 : 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        guard let listSection = ListSection(rawValue: indexPath.section) else {
            assertionFailure("Invalid section")
            return cell
        }
        
        switch listSection {
        case .launches:
            let launch = self.launches[indexPath.row]
            cell.textLabel?.text = launch.mission?.name
            cell.detailTextLabel?.text = launch.site
            
            let placeholder = UIImage(named: "placeholder")!
            
            if let missionPatch = launch.mission?.missionPatch {
                cell.imageView?.sd_setImage(with: URL(string: missionPatch)!, placeholderImage: placeholder)
            } else {
                cell.imageView?.image = placeholder
            }
        case .loading:
            cell.textLabel?.text = self.activeRequest != nil ? "Loading..." : "Tap to load more"
        }
        
        return cell
    }
    
    private func loadMoreLaunchesIfTheyExist() {
        guard let connection = self.lastConnection else {
            self.loadMoreLaunches(from: nil)
            return
        }
        
        guard connection.hasMore else { return }
        
        self.loadMoreLaunches(from: connection.cursor)
    }
    
    private func loadMoreLaunches(from cursor: String?) {
        self.activeRequest = Network.shared.apollo.fetch(query: LaunchListQuery(cursor: cursor)) { [weak self] result in
            guard let self = self else { return }
            
            self.activeRequest = nil
            defer {
                self.tableView.reloadData()
            }
            
            switch result {
            case .success(let graphQLResult):
                if let launchConnection = graphQLResult.data?.launches {
                    self.lastConnection = launchConnection
                    self.launches.append(contentsOf: launchConnection.launches.compactMap { $0 })
                }
                
                if let errors = graphQLResult.errors {
                    let message = errors
                        .map { $0.localizedDescription }
                        .joined(separator: "\n")
                    self.showAlert(title: "GraphQL Error(s)",
                                   message: message)
                }
            case .failure(let error):
                self.showAlert(title: "Network Error",
                               message: error.localizedDescription)
            }
        }
    }
}

