module io

import nbt

struct BufferWriter {
mut:
	buf []byte
}

pub fn create_buf_writer() BufferWriter {
	return BufferWriter{}
}

pub fn (writer mut BufferWriter) create_empty() {
	writer.buf = []byte{}
}

pub fn (writer mut BufferWriter) set_buffer(buf []byte) {
	writer.buf = buf
}

pub fn (writer mut BufferWriter) write_var_int(val int) {
	mut data := val
	for {
		mut tmp := (data & 0b01111111)
		data >>= 7

		if data != 0 {
			tmp |= 0b10000000
		}
		writer.buf << byte(tmp)
		if data == 0 {
			break
		}
	}
}

pub fn (writer mut BufferWriter) write_var_long(val i64) {
	mut data := val
	for {
		mut tmp := (data & 0b01111111)
		data >>= 7

		if data != 0 {
			tmp |= 0b10000000
		}
		writer.buf << byte(tmp)
		if data == 0 {
			break
		}
	}
}

pub fn (writer mut BufferWriter) write_string(str string) {
	buf := str.bytes()
	writer.write_var_int(buf.len)
	writer.buf << buf
}

pub fn (writer mut BufferWriter) write_string_enum(str string) {
	buf := str.bytes()
	writer.write_var_int(buf.len)
}

pub fn (writer mut BufferWriter) write_long(l i64) {
	mut v := l
	writer.buf << byte(v>>56)
	writer.buf << byte(v>>48)
	writer.buf << byte(v>>40)
	writer.buf << byte(v>>32)
	writer.buf << byte(v>>24)
	writer.buf << byte(v>>16)
	writer.buf << byte(v>>8)
	writer.buf << byte(v)
}

pub fn (writer mut BufferWriter) write_ulong(l u64) {
	mut v := l
	writer.buf << byte(v>>56)
	writer.buf << byte(v>>48)
	writer.buf << byte(v>>40)
	writer.buf << byte(v>>32)
	writer.buf << byte(v>>24)
	writer.buf << byte(v>>16)
	writer.buf << byte(v>>8)
	writer.buf << byte(v)
}

pub fn (writer mut BufferWriter) write_int(i int) {
	mut v := i
	writer.buf << byte(v>>24)
	writer.buf << byte(v>>16)
	writer.buf << byte(v>>8)
	writer.buf << byte(v)
}

pub fn (writer mut BufferWriter) write_short(l i16) {
	mut v := l
	writer.buf << byte(v>>8)
	writer.buf << byte(v)
}

pub fn (writer mut BufferWriter) write_byte(b byte) {
	writer.buf << b
}

pub fn (writer mut BufferWriter) write_bool(b bool) {
	if b {
		writer.buf << byte(0x01)
	} else {
		writer.buf << byte(0x00)
	}
}

pub fn (writer mut BufferWriter) write_array(b []byte) {
	writer.write_var_int(b.len)
	if b.len > 0 {
		writer.buf << b
	}
}

pub fn (writer mut BufferWriter) write_position(x, y, z int) {
	b := byte(((x & 0x3FFFFFF) << 38) | ((z & 0x3FFFFFF) << 12) | (y & 0xFFF))
	writer.buf << b
}

pub fn (writer mut BufferWriter) write_empty_heightmap() {
	writer.write_byte(byte(10))
	writer.write_byte(0)
	writer.write_byte(0)
	writer.write_byte(byte(12))
	writer.write_nbt_text('MOTION_BLOCKING')
	writer.write_int(0)
}

pub fn (writer mut BufferWriter) write_nbt(data nbt.NbtCompound) {
	writer.write_byte(byte(data.typ()))
	writer.write_byte(0)
	writer.write_byte(0)
	writer.write_nbt_data(data)
}

fn (writer mut BufferWriter) write_nbt_data(data nbt.Nbt) {
	match data {
		nbt.NbtEnd {
			
		}
		nbt.NbtByte {
			writer.write_byte(byte(it.val))
		}
		nbt.NbtCompound {
			val := it.val
			for _, tag in val {
				tagid := get_typ(tag)
				tagname := get_name(tag)
				writer.write_byte(tagid)

				if byte(tagid) == 0 {
					continue
				}

				writer.write_nbt_text(tagname)
				writer.write_nbt_data(tag)
			}
		}
		nbt.NbtLongArray {
			writer.write_int(it.val.len)

			for v in it.val {
				writer.write_long(v)
			}
		}
	}
}

fn get_typ(data nbt.Nbt) nbt.Typ {
	match data {
		nbt.NbtEnd {
			return it.typ()
		}
		nbt.NbtByte {
			return it.typ()
		}
		nbt.NbtCompound {
			return it.typ()
		}
		nbt.NbtLongArray {
			return it.typ()
		}
	}
}

fn get_name(data nbt.Nbt) string {
	match data {
		nbt.NbtEnd {
			return it.name()
		}
		nbt.NbtByte {
			return it.name()
		}
		nbt.NbtCompound {
			return it.name()
		}
		nbt.NbtLongArray {
			return it.name()
		}
	}
}

fn (writer mut BufferWriter) write_nbt_text(data string) {
	writer.write_short(data.len)
	writer.buf << data.bytes()
}

pub fn (writer mut BufferWriter) write(b []byte) {
	writer.buf << b
}

pub fn (writer mut BufferWriter) flush(id int) []byte {
	mut buf := writer.buf.clone()
	writer.create_empty()

	mut pkt_id := [byte(0x00)]
	if id > 0 {
		writer.write_var_int(id)
		pkt_id = writer.buf.clone()
		writer.create_empty()
	}

	writer.write_var_int(buf.len + pkt_id.len)
	mut buf_len := writer.buf.clone()
	writer.create_empty()

	buf_len << pkt_id
	buf_len << buf

	return buf_len
}

pub fn (writer mut BufferWriter) to_buffer() []byte {
	return writer.buf
}