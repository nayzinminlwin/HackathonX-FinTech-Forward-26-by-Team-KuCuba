class QuickScanExample {
  const QuickScanExample({required this.text, required this.preview});

  final String text;
  final String preview;
}

class RecentScan {
  const RecentScan({
    required this.time,
    required this.risk,
    required this.message,
  });

  final String time;
  final int risk;
  final String message;
}

const quickScanExamples = <QuickScanExample>[
  QuickScanExample(
    text: 'URGENT! Bank account suspended. Click: http://fake-bank.xyz',
    preview: 'Suspicious link detected',
  ),
  QuickScanExample(
    text: 'Congratulations! You won RM50,000. Send RM500 fee to claim prize.',
    preview: 'Prize scam pattern',
  ),
  QuickScanExample(
    text: 'Hi! Meeting you at 1pm today?',
    preview: 'Normal conversation',
  ),
];

const recentScans = <RecentScan>[
  RecentScan(time: '10 mins ago', risk: 92, message: 'Malicious link detected'),
  RecentScan(time: '2 hours ago', risk: 15, message: 'Safe message'),
  RecentScan(time: 'Yesterday', risk: 78, message: 'Urgent payment request'),
];
