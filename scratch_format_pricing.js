const fs = require('fs');
const path = 'c:/Users/yashs/office projects/krishikranti/lib/screens/product_detail_screen.dart';

let content = fs.readFileSync(path, 'utf8');

// Use a CRLF-insensitive regex to match the exact pricing block
const regex = /const\s+SizedBox\(\s*height:\s*1\s*\),\s*Wrap\(\s*spacing:\s*4,\s*runSpacing:\s*1,\s*crossAxisAlignment:\s*WrapCrossAlignment\.center,\s*children:\s*\[\s*Text\(\s*["']₹\$\{v\.price\.toStringAsFixed\(0\)\}["'],\s*style:\s*const\s*TextStyle\(\s*color:\s*Colors\.black,\s*fontWeight:\s*FontWeight\.w900,\s*fontSize:\s*13,\s*\),\s*\),\s*if\s*\(perUnitLabel\s*!=\s*null\)\s*\.\.\.\[\s*Text\(\s*["']\(\$perUnitLabel\)["'],\s*style:\s*TextStyle\(\s*color:\s*primaryGreen,\s*fontSize:\s*10,\s*fontWeight:\s*FontWeight\.w900,\s*\),\s*\),\s*\]\s*,\s*if\s*\(v\.compareAtPrice\s*>\s*v\.price\)\s*\.\.\.\[\s*Text\(\s*["']₹\$\{v\.compareAtPrice\.toStringAsFixed\(0\)\}["'],\s*style:\s*const\s*TextStyle\(\s*color:\s*Colors\.black54,\s*decoration:\s*TextDecoration\.lineThrough,\s*fontSize:\s*9\.5,\s*\),\s*\),\s*Container\(\s*padding:\s*const\s*EdgeInsets\.symmetric\(\s*horizontal:\s*4,\s*vertical:\s*1,\s*\),\s*decoration:\s*BoxDecoration\(\s*color:\s*Colors\.red\.shade50,\s*borderRadius:\s*BorderRadius\.circular\(\s*3,\s*\),\s*\),\s*child:\s*Text\(\s*["']\$\{[\s\S]*?\}% OFF["'],\s*style:\s*TextStyle\(\s*color:\s*Colors\.red\.shade800,\s*fontWeight:\s*FontWeight\.w900,\s*fontSize:\s*7\.5,\s*\),\s*\),\s*\),\s*\]\s*,\s*\]\s*,\s*\),/;

const replacement = `const SizedBox(height: 2),
                                   // Row 1: Selling Price and Per-Unit label
                                   Row(
                                     crossAxisAlignment: CrossAxisAlignment.baseline,
                                     textBaseline: TextBaseline.alphabetic,
                                     children: [
                                       Text(
                                         "₹\${v.price.toStringAsFixed(0)}",
                                         style: const TextStyle(
                                           color: Colors.black,
                                           fontWeight: FontWeight.w900,
                                           fontSize: 13.5,
                                         ),
                                       ),
                                       if (perUnitLabel != null) ...[
                                         const SizedBox(width: 4),
                                         Text(
                                           "(\$perUnitLabel)",
                                           style: TextStyle(
                                             color: primaryGreen,
                                             fontSize: 9.5,
                                             fontWeight: FontWeight.w900,
                                           ),
                                         ),
                                       ],
                                     ],
                                   ),
                                   // Row 2: Original Price and Save Percentage (only if discounted)
                                   if (v.compareAtPrice > v.price) ...[
                                     const SizedBox(height: 2),
                                     Row(
                                       crossAxisAlignment: CrossAxisAlignment.center,
                                       children: [
                                         Text(
                                           "₹\${v.compareAtPrice.toStringAsFixed(0)}",
                                           style: const TextStyle(
                                             color: Colors.black54,
                                             decoration: TextDecoration.lineThrough,
                                             fontSize: 9.5,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                         const SizedBox(width: 4),
                                         Container(
                                           padding: const EdgeInsets.symmetric(
                                             horizontal: 4,
                                             vertical: 1,
                                           ),
                                           decoration: BoxDecoration(
                                             color: Colors.red.shade50,
                                             borderRadius: BorderRadius.circular(3),
                                           ),
                                           child: Text(
                                             "\${((v.compareAtPrice - v.price) / v.compareAtPrice * 100).toStringAsFixed(0)}% OFF",
                                             style: TextStyle(
                                               color: Colors.red.shade800,
                                               fontWeight: FontWeight.w900,
                                               fontSize: 7.5,
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],`;

if (regex.test(content)) {
  content = content.replace(regex, replacement);
  fs.writeFileSync(path, content, 'utf8');
  console.log('SUCCESS: pricing split written.');
} else {
  console.log('NOT FOUND: block did not match regex.');
}
