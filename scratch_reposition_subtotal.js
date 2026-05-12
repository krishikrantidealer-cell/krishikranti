const fs = require('fs');
const path = 'c:/Users/yashs/office projects/krishikranti/lib/screens/product_detail_screen.dart';

let content = fs.readFileSync(path, 'utf8');

// 1. Locate the AnimatedContainer for subtotal inside the Right Card.
const subtotalRegex = /AnimatedContainer\(\s*duration:\s*const\s*Duration\(milliseconds:\s*200\),\s*curve:\s*Curves\.easeInOut,\s*height:\s*isSelected\s*\?\s*20\s*:\s*0,[\s\S]*?const\s*SizedBox\.shrink\(\),\s*\),\s*\),/;

const subtotalMatch = content.match(subtotalRegex);
if (!subtotalMatch) {
  console.log('ERROR: subtotal AnimatedContainer not found.');
  process.exit(1);
}

const subtotalBlock = subtotalMatch[0];

// Remove the subtotal block from its original position
content = content.replace(subtotalBlock, '');

// Now let's restructure the return Padding statement
const targetStart = `            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IntrinsicHeight(`;

const replacementStart = `            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicHeight(`;

if (!content.includes(targetStart)) {
  console.log('ERROR: target return Padding start not found.');
  process.exit(1);
}

content = content.replace(targetStart, replacementStart);

// Now, replace the end of the list item builder to append our subtotal block
const targetEnd = `                  ],
                ),
              ),
            );
          }).toList()`;

// Format the subtotal block to be perfectly indented and have margin-left: 74
const formattedSubtotal = subtotalBlock
  .replace(/margin:\s*EdgeInsets\.only\(\s*top:\s*isSelected\s*\?\s*4\s*:\s*0,\s*\),/, `margin: EdgeInsets.only(
                      top: isSelected ? 4 : 0,
                      left: 74, // Perfectly aligns with the start of the Right Card (66 width + 8 spacing)
                    )`)
  .split('\n')
  .map(line => '                  ' + line.trim())
  .join('\n');

const replacementEnd = `                  ],
                ),
              ),
${formattedSubtotal}
                ],
              ),
            );
          }).toList()`;

if (!content.includes(targetEnd)) {
  console.log('ERROR: target end of mapping function not found.');
  process.exit(1);
}

content = content.replace(targetEnd, replacementEnd);
fs.writeFileSync(path, content, 'utf8');
console.log('SUCCESS: subtotal repositioned beneath cards.');
