import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let stack = UIStackView()
    private let heading = UILabel()
    private let incidentTitle = UILabel()
    private let location = UILabel()
    private let priority = UILabel()
    private let followUp = UILabel()
    private let nextStep = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        heading.text = "Campus IT follow-up"
        heading.textColor = .systemBlue
        nextStep.text = "Check the equipment, then open the app to record your progress."
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        for label in [heading, incidentTitle, location, priority, followUp, nextStep] {
            label.numberOfLines = 0
            label.font = .preferredFont(forTextStyle: .subheadline)
            label.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(label)
        }
        heading.font = .preferredFont(forTextStyle: .headline)
        incidentTitle.font = .preferredFont(forTextStyle: .title3)
        nextStep.font = .preferredFont(forTextStyle: .footnote)
        nextStep.textColor = .secondaryLabel
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        ])
    }

    func didReceive(_ notification: UNNotification) {
        loadViewIfNeeded()
        guard let content = IncidentReminderContent(userInfo: notification.request.content.userInfo) else {
            incidentTitle.text = "Incident details unavailable"
            location.text = nil
            priority.text = nil
            followUp.text = nil
            nextStep.text = "Open the app to check your saved incident and follow-up time."
            return
        }
        incidentTitle.text = content.title
        location.text = content.locationName
        priority.text = "Priority: \(content.priority)"
        followUp.text = "Follow-up: \(content.followUpAt.formatted(date: .abbreviated, time: .shortened))"
        nextStep.text = "Check the equipment, then open the app to record your progress."
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = stack.systemLayoutSizeFitting(
            CGSize(width: max(view.bounds.width - 32, 1), height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        )
        preferredContentSize = CGSize(width: view.bounds.width, height: size.height + 32)
    }
}
